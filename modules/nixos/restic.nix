{
  config,
  lib,
  pkgs,
  options,
  ...
}:

let
  inherit (lib)
    elem
    mkEnableOption
    mkIf
    mkDefault
    mkOption
    types
    optionalAttrs
    mapAttrsToList
    filterAttrs
    escapeShellArg
    ;

  cfg = config.mine.services.restic;

  forcedKeys = [
    "_module"
    "repository"
    "repositoryFile"
    "rcloneConfigFile"
    "rcloneConfig"
    "passwordFile"
    "environmentFile"
    "initialize"
    "createWrapper"
    "runCheck"
  ];

  upstreamResticOptions = removeAttrs (options.services.restic.backups.type.getSubOptions
    [ ]
  ) forcedKeys;

  notifyScript = pkgs.writeShellScript "restic-backup-notify-failure.sh" ''
    set -euo pipefail
    UNIT="$1"
    NOTIFY_USER=${escapeShellArg cfg.onFailure.notifyUser}
    UID_NUM=$(${pkgs.coreutils}/bin/id -u "$NOTIFY_USER")
    export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/''${UID_NUM}/bus"
    ${pkgs.util-linux}/bin/runuser -u "$NOTIFY_USER" -- \
      ${pkgs.libnotify}/bin/notify-send \
        -u critical \
        -a "restic-backup" \
        "Restic Backup Failed" \
        "Unit $UNIT failed. Check: journalctl -u $UNIT"
  '';

  failureNotifyService = optionalAttrs cfg.onFailure.enable {
    "restic-backup-notify-failure@" = {
      description = "Failure notification for %i";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${notifyScript} %i";
      };
    };
  };

  enabledJobs = filterAttrs (_: j: j.enable) cfg.jobs;

  jobProviderPairs = lib.concatLists (
    mapAttrsToList (
      jobName: jobCfg:
      let
        folder = if jobCfg.folder != null then jobCfg.folder else jobName;
        enabledProviders = filterAttrs (
          name: prov: prov.enable && !(elem name jobCfg.excludeProviders)
        ) cfg.providers;
      in
      mapAttrsToList (provName: provCfg: {
        inherit
          jobName
          jobCfg
          provName
          provCfg
          folder
          ;
      }) enabledProviders
    ) enabledJobs
  );

  wrapperKeys = [
    "enable"
    "folder"
    "excludeProviders"
    "backupPrepareCommand"
    "backupCleanupCommand"
  ];

  resticBackups = builtins.listToAttrs (
    map (
      pair:
      let
        resticAttrs = removeAttrs pair.jobCfg wrapperKeys;
      in
      {
        name = "${pair.jobName}-${pair.provName}";
        value = resticAttrs // {
          repository = "rclone:${pair.provCfg.target}/${pair.folder}";
          rcloneConfigFile = config.age.secrets.restic-rclone.path;
          passwordFile = config.age.secrets.restic-password.path;
          initialize = true;
          createWrapper = true;
          runCheck = pair.jobCfg.runCheck;
          timerConfig = null;
        };
      }
    ) jobProviderPairs
  );

in
{
  options.mine.services.restic = {
    enable = mkEnableOption "restic backup wrapper";

    rcloneConfAge = mkOption {
      type = types.path;
      description = "Path to the agenix-encrypted rclone.conf file.";
    };

    passwordFileAge = mkOption {
      type = types.path;
      description = "Path to the agenix-encrypted restic repository password.";
    };

    providers = mkOption {
      description = "Cloud storage providers for restic backups.";
      default = { };
      type = types.attrsOf (
        types.submodule (
          { name, ... }:
          {
            options = {
              enable = mkEnableOption "provider ${name}" // {
                default = true;
              };

              target = mkOption {
                type = types.str;
                description = "rclone target including bucket, e.g. 'storj:restic'.";
              };
            };
          }
        )
      );
    };

    onFailure = {
      enable = mkEnableOption "desktop notifications on backup failure";
      notifyUser = mkOption {
        type = types.str;
        description = "Desktop user whose session receives critical notify-send on failure.";
        example = "vinny";
      };
    };

    defaults = {
      pruneOpts = mkOption {
        type = types.listOf types.str;
        default = [
          "--keep-daily 7"
          "--keep-weekly 5"
          "--keep-monthly 12"
          "--keep-yearly 75"
        ];
        description = "Default prune options for all jobs.";
      };

      timerConfig = mkOption {
        type = types.attrsOf (
          types.oneOf [
            types.bool
            types.str
            types.int
          ]
        );
        default = {
          OnCalendar = "daily";
          Persistent = true;
          RandomizedDelaySec = "1h";
        };
        description = "Default timer configuration for all jobs.";
      };

      checkOpts = mkOption {
        type = types.listOf types.str;
        default = [ "--with-cache" ];
        description = "Default check options for all jobs.";
      };
    };

    jobs = mkOption {
      default = { };
      description = "Named restic backup jobs. Each job backs up to all enabled providers.";
      type = types.attrsOf (
        types.submodule (
          { ... }:
          {
            options = {
              enable = mkEnableOption "restic backup job" // {
                default = true;
              };

              folder = mkOption {
                type = types.nullOr types.str;
                default = null;
                description = "Target folder name within the provider bucket. Defaults to the job name.";
              };

              excludeProviders = mkOption {
                type = types.listOf types.str;
                default = [ ];
                description = "Provider names to exclude from this job.";
              };

              runCheck = mkOption {
                type = types.bool;
                default = true;
                description = "Whether to run restic check after backup.";
              };
            }
            // upstreamResticOptions;

            config = {
              pruneOpts = mkDefault cfg.defaults.pruneOpts;
              timerConfig = mkDefault cfg.defaults.timerConfig;
              checkOpts = mkDefault cfg.defaults.checkOpts;
            };
          }
        )
      );
    };
  };

  config = mkIf cfg.enable (
    let
      allRepos = map (p: "rclone:${p.provCfg.target}/${p.folder}") jobProviderPairs;

      pairsByJob = lib.groupBy (p: p.jobName) jobProviderPairs;

      jobUnits =
        let
          perJob = lib.mapAttrsToList (
            jobName: pairs:
            let
              jobCfg = (builtins.head pairs).jobCfg;
              provBackupServices = map (p: "restic-backups-${p.jobName}-${p.provName}.service") pairs;
              hasPrepare = jobCfg.backupPrepareCommand != null;
              hasCleanup = jobCfg.backupCleanupCommand != null;
            in
            {
              services =
                (lib.optionalAttrs hasPrepare {
                  "restic-prepare-${jobName}" = {
                    description = "Restic backup preparation for ${jobName}";
                    before = provBackupServices;
                    serviceConfig.Type = "oneshot";
                    script = jobCfg.backupPrepareCommand;
                  };
                })
                // (lib.optionalAttrs hasCleanup {
                  "restic-cleanup-${jobName}" = {
                    description = "Restic backup cleanup for ${jobName}";
                    after = provBackupServices;
                    serviceConfig.Type = "oneshot";
                    script = jobCfg.backupCleanupCommand;
                  };
                })
                // builtins.listToAttrs (
                  map (p: {
                    name = "restic-backups-${p.jobName}-${p.provName}";
                    value = {
                      requires = lib.optional hasPrepare "restic-prepare-${jobName}.service";
                      after = lib.optional hasPrepare "restic-prepare-${jobName}.service";
                      before = lib.optional hasCleanup "restic-cleanup-${jobName}.service";
                    };
                  }) pairs
                );

              targets."restic-backups-${jobName}" = {
                description = "Restic backup target for ${jobName}";
                wants =
                  (lib.optional hasPrepare "restic-prepare-${jobName}.service")
                  ++ provBackupServices
                  ++ (lib.optional hasCleanup "restic-cleanup-${jobName}.service");
              };

              timers."restic-backups-${jobName}" = {
                wantedBy = [ "timers.target" ];
                timerConfig = jobCfg.timerConfig // {
                  Unit = "restic-backups-${jobName}.target";
                };
              };
            }
          ) pairsByJob;
        in
        {
          services = lib.foldl' (acc: x: acc // x.services) { } perJob;
          targets = lib.foldl' (acc: x: acc // x.targets) { } perJob;
          timers = lib.foldl' (acc: x: acc // x.timers) { } perJob;
        };
    in
    {
      assertions = [
        {
          assertion = lib.length allRepos == lib.length (lib.unique allRepos);
          message = "restic: duplicate repository paths detected across job/provider pairs.";
        }
        {
          assertion = enabledJobs == { } || filterAttrs (_: p: p.enable) cfg.providers != { };
          message = "restic: jobs are defined but no providers are enabled. Add at least one provider.";
        }
      ];

      age.secrets.restic-rclone = {
        file = cfg.rcloneConfAge;
        mode = "0600";
      };

      age.secrets.restic-password = {
        file = cfg.passwordFileAge;
        mode = "0400";
      };

      services.restic.backups = resticBackups;

      systemd.services = lib.mkMerge [
        failureNotifyService

        jobUnits.services

        (lib.optionalAttrs cfg.onFailure.enable (
          builtins.listToAttrs (
            map (pair: {
              name = "restic-backups-${pair.jobName}-${pair.provName}";
              value = {
                unitConfig.OnFailure = [ "restic-backup-notify-failure@%n.service" ];
              };
            }) jobProviderPairs
          )
        ))

        (lib.optionalAttrs cfg.onFailure.enable (
          builtins.listToAttrs (
            lib.concatMap (
              jobName:
              let
                jobCfg = (builtins.head pairsByJob.${jobName}).jobCfg;
              in
              (lib.optional (jobCfg.backupPrepareCommand != null) {
                name = "restic-prepare-${jobName}";
                value.unitConfig.OnFailure = [ "restic-backup-notify-failure@%n.service" ];
              })
              ++ (lib.optional (jobCfg.backupCleanupCommand != null) {
                name = "restic-cleanup-${jobName}";
                value.unitConfig.OnFailure = [ "restic-backup-notify-failure@%n.service" ];
              })
            ) (builtins.attrNames pairsByJob)
          )
        ))
      ];

      systemd.targets = jobUnits.targets;
      systemd.timers = jobUnits.timers;
    }
  );
}
