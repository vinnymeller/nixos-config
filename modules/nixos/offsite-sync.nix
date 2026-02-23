# modules/nixos/offsite-sync.nix
{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    optional
    optionalAttrs
    optionalString
    concatStringsSep
    mapAttrsToList
    escapeShellArg
    getExe
    ;

  cfg = config.mine.services.offsiteSync;

  mkExcludeArgs = excludes: concatStringsSep " " (map (p: "--exclude ${escapeShellArg p}") excludes);

  mkCliArgs = args: concatStringsSep " " (map escapeShellArg args);

  onFailureUnit = optionalAttrs cfg.onFailure.enable {
    OnFailure = [ "offsite-sync-notify-failure@%n.service" ];
  };

  notifyScript = pkgs.writeShellScript "offsite-sync-notify-failure.sh" ''
    set -euo pipefail
    UNIT="$1"
    NOTIFY_USER=${escapeShellArg cfg.onFailure.notifyUser}
    UID_NUM=$(${pkgs.coreutils}/bin/id -u "$NOTIFY_USER")
    export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/''${UID_NUM}/bus"
    ${pkgs.util-linux}/bin/runuser -u "$NOTIFY_USER" -- \
      ${pkgs.libnotify}/bin/notify-send \
        -u critical \
        -a "offsite-sync" \
        "Offsite Sync Failed" \
        "Unit $UNIT failed. Check: journalctl -u $UNIT"
  '';

  failureNotifyService = optionalAttrs cfg.onFailure.enable {
    "offsite-sync-notify-failure@" = {
      description = "Failure notification for %i";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${notifyScript} %i";
      };
    };
  };

  # Generate effective destinations for a job from module-level providers
  mkEffectiveDestinations =
    jobName: jobCfg:
    let
      folder = if jobCfg.folder != null then jobCfg.folder else jobName;
      enabledProviders = lib.filterAttrs (
        name: prov: prov.enable && !(builtins.elem name jobCfg.excludeProviders)
      ) cfg.providers;
    in
    lib.mapAttrs (provName: provCfg: {
      remote = "${provCfg.remote}:${folder}";
      extraArgs = provCfg.extraArgs;
      checkExtraArgs = provCfg.checkExtraArgs;
      timer = null;
    }) enabledProviders;

  mkJobDestService =
    jobName: jobCfg: destName: destCfg:
    let
      unitName = "offsite-sync-${jobName}-${destName}";
      modeCmd = jobCfg.mode;
      src = jobCfg.source;
      dst = destCfg.remote;
      allArgs =
        jobCfg.extraArgs
        ++ destCfg.extraArgs
        ++ optional jobCfg.createEmptySrcDirs "--create-empty-src-dirs";
      script = pkgs.writeShellScript "${unitName}.sh" ''
        set -euo pipefail

        export PATH=${
          lib.makeBinPath [
            pkgs.coreutils
            pkgs.findutils
            pkgs.gnugrep
            pkgs.gawk
            pkgs.bash
            pkgs.rclone
          ]
        }:$PATH
        export RCLONE_CONFIG=${escapeShellArg config.age.secrets.offsite-sync-rclone.path}

        ${optionalString (jobCfg.preflight != "") ''
          echo "[offsite-sync] running preflight for ${jobName}/${destName}"
          ${jobCfg.preflight}
        ''}

        echo "[offsite-sync] rclone ${modeCmd} ${src} -> ${dst}"
        exec ${getExe pkgs.rclone} ${modeCmd} \
          ${escapeShellArg src} \
          ${escapeShellArg dst} \
          ${mkExcludeArgs jobCfg.excludes} \
          ${mkCliArgs allArgs}
      '';
    in
    {
      name = unitName;
      value = {
        description = "Offsite sync (${jobName} -> ${destName}) via rclone";
        after = [ "network-online.target" ] ++ jobCfg.afterUnits;
        wants = [ "network-online.target" ];
        wantedBy = [ ]; # timer starts it
        serviceConfig = {
          Type = "oneshot";
          User = jobCfg.user;
          Group = jobCfg.group;
          ExecStart = script;
          Nice = jobCfg.nice;
          IOSchedulingClass = jobCfg.ioSchedulingClass;
          IOSchedulingPriority = jobCfg.ioSchedulingPriority;
          TimeoutStartSec = jobCfg.timeoutStartSec;
        };
        environment = jobCfg.environment;
        unitConfig = onFailureUnit;
      };
    };

  # Build per-destination timer (lets you stagger remotes independently)
  mkJobDestTimer =
    jobName: jobCfg: destName: destCfg:
    let
      unitName = "offsite-sync-${jobName}-${destName}";
      timerName = unitName;
      timerCfg = if destCfg.timer != null then destCfg.timer else jobCfg.timer;
    in
    {
      name = timerName;
      value = {
        description = "Timer for ${unitName}";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = timerCfg.onCalendar;
          Persistent = timerCfg.persistent;
          RandomizedDelaySec = timerCfg.randomizedDelaySec;
          Unit = "${unitName}.service";
        };
      };
    };

  mkJobDestCheckService =
    jobName: jobCfg: destName: destCfg:
    let
      unitName = "offsite-sync-check-${jobName}-${destName}";
      src = jobCfg.source;
      dst = destCfg.remote;
      checkArgs = jobCfg.check.extraArgs ++ destCfg.checkExtraArgs;
      script = pkgs.writeShellScript "${unitName}.sh" ''
        set -euo pipefail

        export PATH=${
          lib.makeBinPath [
            pkgs.coreutils
            pkgs.bash
            pkgs.rclone
          ]
        }:$PATH
        export RCLONE_CONFIG=${escapeShellArg config.age.secrets.offsite-sync-rclone.path}

        ${optionalString (jobCfg.preflight != "") ''
          echo "[offsite-sync] running preflight for check ${jobName}/${destName}"
          ${jobCfg.preflight}
        ''}

        echo "[offsite-sync] rclone check ${src} vs ${dst}"
        exec ${getExe pkgs.rclone} check \
          ${escapeShellArg src} \
          ${escapeShellArg dst} \
          --one-way \
          ${mkExcludeArgs jobCfg.excludes} \
          ${mkCliArgs checkArgs}
      '';
    in
    {
      name = unitName;
      value = {
        description = "Offsite sync verification (${jobName} -> ${destName})";
        after = [ "network-online.target" ] ++ jobCfg.afterUnits;
        wants = [ "network-online.target" ];
        serviceConfig = {
          Type = "oneshot";
          User = jobCfg.user;
          Group = jobCfg.group;
          ExecStart = script;
          Nice = jobCfg.nice;
          IOSchedulingClass = jobCfg.ioSchedulingClass;
          IOSchedulingPriority = jobCfg.ioSchedulingPriority;
          TimeoutStartSec = jobCfg.timeoutStartSec;
        };
        environment = jobCfg.environment;
        unitConfig = onFailureUnit;
      };
    };

  mkJobDestCheckTimer =
    jobName: jobCfg: destName: destCfg:
    let
      unitName = "offsite-sync-check-${jobName}-${destName}";
    in
    {
      name = unitName;
      value = {
        description = "Verification timer for ${unitName}";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = jobCfg.check.onCalendar;
          Persistent = jobCfg.check.persistent;
          RandomizedDelaySec = jobCfg.check.randomizedDelaySec;
          Unit = "${unitName}.service";
        };
      };
    };

  enabledJobs = lib.filterAttrs (_: j: j.enable) cfg.jobs;

  # Flatten (job, destination) pairs for enabled jobs
  jobDestPairs = lib.concatLists (
    mapAttrsToList (
      jobName: jobCfg:
      let
        effectiveDests = mkEffectiveDestinations jobName jobCfg;
      in
      mapAttrsToList (destName: destCfg: {
        inherit
          jobName
          jobCfg
          destName
          destCfg
          ;
      }) effectiveDests
    ) enabledJobs
  );

  servicesAttr = builtins.listToAttrs (
    map (x: mkJobDestService x.jobName x.jobCfg x.destName x.destCfg) jobDestPairs
  );
  timersAttr = builtins.listToAttrs (
    map (x: mkJobDestTimer x.jobName x.jobCfg x.destName x.destCfg) jobDestPairs
  );

  checkServicesAttr = builtins.listToAttrs (
    map (x: mkJobDestCheckService x.jobName x.jobCfg x.destName x.destCfg) (
      lib.filter (x: x.jobCfg.check.enable) jobDestPairs
    )
  );

  checkTimersAttr = builtins.listToAttrs (
    map (x: mkJobDestCheckTimer x.jobName x.jobCfg x.destName x.destCfg) (
      lib.filter (x: x.jobCfg.check.enable) jobDestPairs
    )
  );

in
{
  options.mine.services.offsiteSync = {
    enable = mkEnableOption "generic offsite sync jobs using rclone (supports crypt remotes)";

    rclone.secretFile = mkOption {
      type = types.path;
      description = "Path to the agenix-encrypted rclone.conf file.";
      example = ../../secrets/vinnix/rclone.conf.age;
    };

    providers = mkOption {
      description = "Cloud storage providers available for sync jobs. Each job syncs to all enabled providers by default.";
      default = { };
      type = types.attrsOf (
        types.submodule (
          { name, ... }:
          {
            options = {
              enable = mkEnableOption "provider ${name}" // {
                default = true;
              };

              remote = mkOption {
                type = types.str;
                description = "Base rclone remote name (without path), e.g. gdrive-crypt";
              };

              extraArgs = mkOption {
                type = types.listOf types.str;
                default = [ ];
                description = "Extra rclone args for this provider.";
              };

              checkExtraArgs = mkOption {
                type = types.listOf types.str;
                default = [ ];
                description = "Extra rclone check args for this provider.";
              };
            };
          }
        )
      );
    };

    onFailure = {
      enable = mkEnableOption "desktop notifications (notify-send) on sync/check failure";
      notifyUser = mkOption {
        type = types.str;
        description = "Desktop user whose session receives critical notify-send on failure.";
        example = "vinny";
      };
    };

    jobs = mkOption {
      default = { };
      description = "Named offsite sync jobs. Each job syncs to all enabled providers by default.";
      type = types.attrsOf (
        types.submodule (
          { name, ... }:
          {
            options = {
              enable = mkEnableOption "offsite sync job" // {
                default = true;
              };

              description = mkOption {
                type = types.str;
                default = "Offsite sync job ${name}";
                description = "Human-readable description for the job.";
              };

              source = mkOption {
                type = types.str;
                description = "Local source directory to sync/copy.";
                example = "/var/lib/immich";
              };

              folder = mkOption {
                type = types.nullOr types.str;
                default = null;
                description = "Remote folder name appended to each provider remote. Defaults to the job name.";
              };

              excludeProviders = mkOption {
                type = types.listOf types.str;
                default = [ ];
                description = "Provider names to exclude from this job.";
                example = [ "onedrive" ];
              };

              mode = mkOption {
                type = types.enum [
                  "copy"
                  "sync"
                ];
                default = "copy";
                description = ''
                  rclone mode:
                  - "copy": copy new/changed files only, do not delete remote-only files
                  - "sync": mirror source to destination (deletes remote-only files)
                '';
              };

              user = mkOption {
                type = types.str;
                default = "root";
                description = "User to run the rclone service as.";
              };

              group = mkOption {
                type = types.str;
                default = "root";
                description = "Group to run the rclone service as.";
              };

              excludes = mkOption {
                type = types.listOf types.str;
                default = [ ];
                description = "rclone --exclude patterns.";
                example = [
                  "/cache/**"
                  "/thumbs/**"
                  "*.log"
                ];
              };

              createEmptySrcDirs = mkOption {
                type = types.bool;
                default = true;
                description = "Pass --create-empty-src-dirs to rclone.";
              };

              extraArgs = mkOption {
                type = types.listOf types.str;
                default = [
                  "--fast-list"
                  "--transfers=8"
                  "--checkers=16"
                  "--log-level=INFO"
                ];
                description = "Additional rclone args applied to all destinations for this job.";
              };

              environment = mkOption {
                type = types.attrsOf types.str;
                default = { };
                description = "Extra environment variables for the service unit.";
              };

              preflight = mkOption {
                type = types.lines;
                default = "";
                description = ''
                  Shell snippet run before rclone command.
                  Useful for sanity checks (e.g. verify a recent DB dump exists).
                '';
              };

              afterUnits = mkOption {
                type = types.listOf types.str;
                default = [ ];
                description = "Additional systemd units this job should run after.";
              };

              timeoutStartSec = mkOption {
                type = types.str;
                default = "24h";
                description = "systemd TimeoutStartSec for sync/check jobs.";
              };

              nice = mkOption {
                type = types.int;
                default = 10;
                description = "CPU scheduling niceness.";
              };

              ioSchedulingClass = mkOption {
                type = types.enum [
                  "realtime"
                  "best-effort"
                  "idle"
                ];
                default = "best-effort";
                description = "IOSchedulingClass for the systemd service.";
              };

              ioSchedulingPriority = mkOption {
                type = types.int;
                default = 7;
                description = "IOSchedulingPriority for best-effort/realtime classes (0-7; lower is higher priority).";
              };

              timer = {
                onCalendar = mkOption {
                  type = types.str;
                  default = "daily";
                  description = "Systemd OnCalendar expression for the main sync job.";
                };
                persistent = mkOption {
                  type = types.bool;
                  default = true;
                  description = "Run missed timer invocation on next boot.";
                };
                randomizedDelaySec = mkOption {
                  type = types.str;
                  default = "0";
                  description = "Randomized delay to spread load.";
                };
              };

              check = {
                enable = mkEnableOption "periodic rclone check verification" // {
                  default = false;
                };
                onCalendar = mkOption {
                  type = types.str;
                  default = "monthly";
                  description = "Systemd OnCalendar for verification checks.";
                };
                persistent = mkOption {
                  type = types.bool;
                  default = true;
                  description = "Run missed verification on next boot.";
                };
                randomizedDelaySec = mkOption {
                  type = types.str;
                  default = "1d";
                  description = "Randomized delay for checks.";
                };
                extraArgs = mkOption {
                  type = types.listOf types.str;
                  default = [
                    "--checkers=8"
                    "--size-only"
                  ];
                  description = "Extra args passed to rclone check for all destinations.";
                };
              };
            };
          }
        )
      );
    };
  };

  config = mkIf cfg.enable (
    let
      allRemotes = map (x: x.destCfg.remote) jobDestPairs;
      uniqueRemotes = lib.unique allRemotes;
    in
    {
      assertions = [
        {
          assertion = lib.length allRemotes == lib.length uniqueRemotes;
          message = "offsite-sync: duplicate destination remotes detected. Each destination must have a unique remote path.";
        }
      ];

      age.secrets.offsite-sync-rclone = {
        file = cfg.rclone.secretFile;
        mode = "0600"; # writable so rclone can refresh OAuth tokens
      };

      environment.systemPackages = [ pkgs.rclone ];
      systemd.services = servicesAttr // checkServicesAttr // failureNotifyService;
      systemd.timers = timersAttr // checkTimersAttr;
    }
  );
}
