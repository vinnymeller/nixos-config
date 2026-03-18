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
    mapAttrsToList
    concatLists
    filterAttrs
    mapAttrs
    optionalAttrs
    recursiveUpdate
    ;

  cfg = config.mine.services.dockerCompose;

  jsonFormat = pkgs.formats.json { };

  enabledStacks = filterAttrs (_: s: s.enable) cfg.stacks;

  mkStackConfig =
    name: stackCfg:
    let
      hasEnvFile = stackCfg.agenix.envFile.file != null;
      hasSecrets = stackCfg.agenix.secrets != { };
      hasSecretsOverride = hasEnvFile || hasSecrets;

      # ── Compose File ──
      composeFile =
        if stackCfg.compose != null then
          jsonFormat.generate "dc-${name}-docker-compose.json" stackCfg.compose
        else
          stackCfg.composeFile;

      # ── Secrets Override ──
      envSecretName = "dc-${name}-env";
      envPath = config.age.secrets.${envSecretName}.path;
      envTargets =
        if stackCfg.agenix.envFile.services != null then
          stackCfg.agenix.envFile.services
        else
          builtins.attrNames (stackCfg.compose.services or { });

      envFileOverride = optionalAttrs hasEnvFile {
        services = lib.genAttrs envTargets (_: {
          env_file = [
            {
              path = envPath;
              required = true;
              format = "raw";
            }
          ];
        });
      };

      secretVolumes =
        let
          allMounts = concatLists (
            mapAttrsToList (
              sName: sCfg:
              let
                roSuffix = if sCfg.readOnly then ":ro" else "";
                mount = "${config.age.secrets."dc-${name}-${sName}".path}:${sCfg.containerPath}${roSuffix}";
              in
              map (svc: {
                name = svc;
                value = mount;
              }) sCfg.services
            ) stackCfg.agenix.secrets
          );

          grouped = lib.foldl' (
            acc: pair:
            acc
            // {
              ${pair.name} = (acc.${pair.name} or [ ]) ++ [ pair.value ];
            }
          ) { } allMounts;
        in
        optionalAttrs (grouped != { }) {
          services = mapAttrs (_: mounts: { volumes = mounts; }) grouped;
        };

      secretsOverride = recursiveUpdate envFileOverride secretVolumes;

      secretsOverrideFile = jsonFormat.generate "dc-${name}-secrets-override.json" secretsOverride;

      # ── GPU Override ──
      hasGpu = stackCfg.gpu.services != [ ];

      gpuOverride = {
        services = lib.genAttrs stackCfg.gpu.services (_: {
          devices = [ "nvidia.com/gpu=all" ];
        });
      };
      gpuOverrideFile = jsonFormat.generate "dc-${name}-gpu-override.json" gpuOverride;

      # ── Logging Override ──
      loggingOptions =
        if stackCfg.logging.options != { } then
          stackCfg.logging.options
        else if stackCfg.logging.driver == "journald" then
          { tag = name; }
        else
          { };

      loggingOverride = {
        services = lib.genAttrs (builtins.attrNames (stackCfg.compose.services or { })) (_: {
          logging = {
            driver = stackCfg.logging.driver;
            options = loggingOptions;
          };
        });
      };
      loggingOverrideFile = jsonFormat.generate "dc-${name}-logging-override.json" loggingOverride;

      # ── Compose Command ──
      composeFiles = [
        composeFile
      ]
      ++ lib.optional hasSecretsOverride secretsOverrideFile
      ++ lib.optional hasGpu gpuOverrideFile
      ++ lib.optional stackCfg.logging.enable loggingOverrideFile
      ++ stackCfg.composeOverrides;

      composeFFlags = lib.concatMapStringsSep " " (f: "-f ${f}") composeFiles;

      projectDirFlag =
        if stackCfg.projectDirectory != null then
          "--project-directory ${lib.escapeShellArg stackCfg.projectDirectory}"
        else
          "";

      envFileFlag =
        if stackCfg.composeEnvFile != null then "--env-file ${stackCfg.composeEnvFile}" else "";

      composeCmd = lib.concatStringsSep " " (
        lib.filter (s: s != "") [
          "${pkgs.docker}/bin/docker compose"
          "-p ${lib.escapeShellArg stackCfg.projectName}"
          projectDirFlag
          composeFFlags
          envFileFlag
        ]
      );

      # ── Agenix Secrets ──
      envSecret = optionalAttrs hasEnvFile {
        ${envSecretName} = {
          file = stackCfg.agenix.envFile.file;
          mode = stackCfg.agenix.envFile.mode;
        };
      };

      fileSecrets =
        mapAttrs
          (sName: sCfg: {
            file = sCfg.file;
            mode = sCfg.mode;
            owner = sCfg.owner;
            group = sCfg.group;
          })
          (lib.mapAttrs' (sName: sCfg: lib.nameValuePair "dc-${name}-${sName}" sCfg) stackCfg.agenix.secrets);

      # ── Reload Triggers ──
      reloadTriggers = [
        composeFile
      ]
      ++ lib.optional hasSecretsOverride secretsOverrideFile
      ++ lib.optional stackCfg.logging.enable loggingOverrideFile
      ++ stackCfg.composeOverrides
      ++ lib.optional hasEnvFile stackCfg.agenix.envFile.file
      ++ mapAttrsToList (_: s: s.file) stackCfg.agenix.secrets
      ++ lib.optional (stackCfg.composeEnvFile != null) stackCfg.composeEnvFile;

      # ── Flock ──
      lockFile = "/run/docker-compose-${name}.lock";
      flock = "${pkgs.util-linux}/bin/flock ${lockFile}";

      # ── Update Service & Timer ──
      pullTargets =
        let
          allServices = builtins.attrNames (stackCfg.compose.services or { });
          excluded = stackCfg.autoUpdate.exclude;
        in
        lib.filter (s: !lib.elem s excluded) allServices;

      pullTargetsStr = lib.concatStringsSep " " pullTargets;

      updateScript = pkgs.writeShellScript "docker-compose-${name}-update" ''
        # Skip if stack not running
        systemctl is-active --quiet docker-compose-${name}.service || exit 0
        # Pull under lock (serialized with main service operations)
        flock ${lockFile} ${composeCmd} pull -q --ignore-buildable ${pullTargetsStr}
        # Reload OUTSIDE lock — ExecReload acquires its own flock
        systemctl reload docker-compose-${name}.service
      '';

      # ── tmpfiles Rules ──
      tmpfilesRules = mapAttrsToList (
        path: dirCfg: "d ${path} ${dirCfg.mode} ${dirCfg.owner} ${dirCfg.group} -"
      ) stackCfg.storage.directories;

      # ── Restic Backup Job ──
      resticJob = lib.optionalAttrs stackCfg.backup.enable {
        ${name} = {
          inherit (stackCfg.backup) paths exclude extraBackupArgs;
        }
        // lib.optionalAttrs (stackCfg.backup.backupPrepareCommand != null) {
          inherit (stackCfg.backup) backupPrepareCommand;
        }
        // lib.optionalAttrs (stackCfg.backup.backupCleanupCommand != null) {
          inherit (stackCfg.backup) backupCleanupCommand;
        }
        // lib.optionalAttrs (stackCfg.backup.timerConfig != null) {
          inherit (stackCfg.backup) timerConfig;
        }
        // lib.optionalAttrs (stackCfg.backup.pruneOpts != null) {
          inherit (stackCfg.backup) pruneOpts;
        };
      };

      # ── Wrapper Script ──
      wrapperScript = lib.optional stackCfg.createWrapper (
        pkgs.writeShellScriptBin "dc-${name}" ''
          exec ${composeCmd} "$@"
        ''
      );

    in
    {
      ageSecrets = envSecret // fileSecrets;

      systemdService = {
        "docker-compose-${name}" = {
          description = "Docker Compose stack: ${name}";
          after = [
            "network-online.target"
            "docker.service"
          ]
          ++ stackCfg.afterUnits;
          requires = [ "docker.service" ] ++ stackCfg.requiresUnits;
          wants = [ "network-online.target" ];
          partOf = [ "docker.service" ];
          wantedBy = [ "multi-user.target" ];

          reloadIfChanged = true;
          restartIfChanged = false;
          restartTriggers = reloadTriggers;

          path = [
            pkgs.docker
            pkgs.util-linux
          ];
          environment = stackCfg.environment;

          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStartPre = "${composeCmd} config -q";
            ExecStart = "${flock} ${composeCmd} up -d --remove-orphans --wait";
            ExecReload = "${flock} ${composeCmd} up -d --remove-orphans --wait";
            ExecStop = "-${flock} ${composeCmd} down";
            TimeoutStartSec = stackCfg.timeoutStartSec;
            TimeoutStopSec = stackCfg.timeoutStopSec;
          };
        };
      };

      updateService = lib.optionalAttrs stackCfg.autoUpdate.enable {
        "docker-compose-${name}-update" = {
          description = "Pull latest images for Docker Compose stack: ${name}";
          after = [
            "network-online.target"
            "docker-compose-${name}.service"
          ];
          wants = [ "network-online.target" ];

          path = [
            pkgs.docker
            pkgs.systemd
            pkgs.util-linux
          ];
          environment = stackCfg.environment;

          serviceConfig = {
            Type = "oneshot";
            ExecStart = updateScript;
            TimeoutStartSec = stackCfg.timeoutStartSec;
          };
        };
      };

      updateTimer = lib.optionalAttrs stackCfg.autoUpdate.enable {
        "docker-compose-${name}-update" = {
          description = "Auto-update timer for Docker Compose stack: ${name}";
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnCalendar = stackCfg.autoUpdate.onCalendar;
            Persistent = stackCfg.autoUpdate.persistent;
            RandomizedDelaySec = stackCfg.autoUpdate.randomizedDelaySec;
            Unit = "docker-compose-${name}-update.service";
          };
        };
      };

      inherit tmpfilesRules resticJob wrapperScript;
    };

  stackConfigs = mapAttrs mkStackConfig enabledStacks;

in
{
  options.mine.services.dockerCompose = {
    enable = mkEnableOption "declarative Docker Compose stack management";

    tailscale = {
      tailnet = mkOption {
        type = types.str;
        default = "";
        description = "Tailscale tailnet name (e.g., 'coyote-fir'). Required when any stack uses tailscale.";
      };
      authKeyFile = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = ''
          Path to a file containing the raw Tailscale auth key (tskey-auth-...).
          Defaults to services.tailscale.authKeyFile if set. Must be a reusable key.
        '';
      };
    };

    stacks = mkOption {
      default = { };
      description = "Docker Compose stacks to manage.";
      type = types.attrsOf (
        types.submodule (
          { name, ... }:
          {
            options = {
              enable = mkEnableOption "stack" // {
                default = true;
              };

              # ── Compose Definition ──
              compose = mkOption {
                type = types.nullOr jsonFormat.type;
                default = null;
                description = "Docker Compose spec as Nix attrset, serialized to JSON.";
              };
              composeFile = mkOption {
                type = types.nullOr types.path;
                default = null;
                description = "External docker-compose.yml path.";
              };
              composeOverrides = mkOption {
                type = types.listOf types.path;
                default = [ ];
                description = "Additional compose files layered via -f flags.";
              };

              # ── Project Settings ──
              projectName = mkOption {
                type = types.str;
                default = name;
                description = "Docker Compose project name (-p flag).";
              };
              projectDirectory = mkOption {
                type = types.nullOr types.str;
                default = null;
                description = ''
                  Working directory for Docker Compose (--project-directory flag).
                  Relative paths in compose files resolve from this directory.
                '';
              };

              # ── Agenix Secrets ──
              agenix = {
                envFile = {
                  file = mkOption {
                    type = types.nullOr types.path;
                    default = null;
                    description = "Age-encrypted dotenv file. Auto-injected into services via generated override.";
                  };
                  services = mkOption {
                    type = types.nullOr (types.listOf types.str);
                    default = null;
                    description = ''
                      Which compose services receive the env file. null = all services.
                      REQUIRED when using composeFile mode (services can't be auto-discovered).
                    '';
                  };
                  mode = mkOption {
                    type = types.str;
                    default = "0440";
                  };
                };

                secrets = mkOption {
                  description = "Individual file secrets mounted into containers via generated override.";
                  default = { };
                  type = types.attrsOf (
                    types.submodule {
                      options = {
                        file = mkOption {
                          type = types.path;
                          description = "Path to .age file.";
                        };
                        mode = mkOption {
                          type = types.str;
                          default = "0400";
                        };
                        owner = mkOption {
                          type = types.str;
                          default = "root";
                        };
                        group = mkOption {
                          type = types.str;
                          default = "root";
                        };
                        containerPath = mkOption {
                          type = types.str;
                          description = "Mount path inside the container.";
                        };
                        services = mkOption {
                          type = types.listOf types.str;
                          description = "Which compose services receive this secret as a volume mount.";
                        };
                        readOnly = mkOption {
                          type = types.bool;
                          default = true;
                        };
                      };
                    }
                  );
                };
              };

              # ── Environment ──
              composeEnvFile = mkOption {
                type = types.nullOr types.path;
                default = null;
                description = "Plain-text .env file for compose variable interpolation (--env-file CLI flag).";
              };
              environment = mkOption {
                type = types.attrsOf types.str;
                default = { };
                description = "Environment variables for the systemd unit.";
              };

              # ── Systemd Tuning ──
              afterUnits = mkOption {
                type = types.listOf types.str;
                default = [ ];
              };
              requiresUnits = mkOption {
                type = types.listOf types.str;
                default = [ ];
              };
              timeoutStartSec = mkOption {
                type = types.str;
                default = "10m";
                description = "Timeout for ExecStart. Override for slow stacks.";
              };
              timeoutStopSec = mkOption {
                type = types.str;
                default = "120s";
              };

              # ── GPU Passthrough ──
              gpu.services = mkOption {
                type = types.listOf types.str;
                default = [ ];
                description = "Compose services that receive GPU devices. Empty list = no GPU.";
              };

              # ── Auto Update ──
              autoUpdate = {
                enable = mkEnableOption "automatic image updates";
                onCalendar = mkOption {
                  type = types.str;
                  default = "daily";
                  description = "systemd calendar expression for update checks.";
                };
                randomizedDelaySec = mkOption {
                  type = types.str;
                  default = "1h";
                  description = "Random delay added to each timer tick.";
                };
                persistent = mkOption {
                  type = types.bool;
                  default = true;
                  description = "Whether missed runs are triggered on next boot.";
                };
                exclude = mkOption {
                  type = types.listOf types.str;
                  default = [ ];
                  description = "Compose services to skip when pulling updates.";
                };
              };

              # ── Storage / tmpfiles ──
              storage.directories = mkOption {
                default = { };
                description = "Host directories to create via systemd-tmpfiles before the stack starts.";
                type = types.attrsOf (
                  types.submodule {
                    options = {
                      mode = mkOption {
                        type = types.str;
                        default = "0755";
                      };
                      owner = mkOption {
                        type = types.str;
                        default = "root";
                      };
                      group = mkOption {
                        type = types.str;
                        default = "root";
                      };
                    };
                  }
                );
              };

              # ── Backup (restic) ──
              backup = {
                enable = mkEnableOption "restic backup for this stack";

                paths = mkOption {
                  type = types.listOf types.str;
                  default = [ ];
                  description = "Paths to back up.";
                };

                exclude = mkOption {
                  type = types.listOf types.str;
                  default = [ ];
                  description = "Paths/patterns to exclude from backup.";
                };

                extraBackupArgs = mkOption {
                  type = types.listOf types.str;
                  default = [ ];
                  description = "Extra arguments passed to restic backup.";
                };

                backupPrepareCommand = mkOption {
                  type = types.nullOr types.str;
                  default = null;
                  description = "Command to run before backup (e.g., database dump).";
                };

                backupCleanupCommand = mkOption {
                  type = types.nullOr types.str;
                  default = null;
                  description = "Command to run after backup completes.";
                };

                timerConfig = mkOption {
                  type = types.nullOr (
                    types.attrsOf (
                      types.oneOf [
                        types.bool
                        types.str
                        types.int
                      ]
                    )
                  );
                  default = null;
                  description = "Override timer config. null uses restic module defaults.";
                };

                pruneOpts = mkOption {
                  type = types.nullOr (types.listOf types.str);
                  default = null;
                  description = "Override prune options. null uses restic module defaults.";
                };
              };

              # ── Logging ──
              logging = {
                enable = mkEnableOption "compose logging override";

                driver = mkOption {
                  type = types.str;
                  default = "journald";
                  description = "Docker logging driver.";
                };

                options = mkOption {
                  type = types.attrsOf types.str;
                  default = { };
                  description = "Logging driver options. Defaults to { tag = stackName; } for journald.";
                };
              };

              # ── Tailscale Proxy ──
              tailscale = {
                serviceName = mkOption {
                  type = types.nullOr types.str;
                  default = null;
                  description = ''
                    Tailscale service name. When set, Caddy creates a tailnet node
                    named <serviceName> and reverse-proxies to the specified port.
                    Accessible at https://<serviceName>.<tailnet>.ts.net
                  '';
                };
                port = mkOption {
                  type = types.port;
                  default = 0;
                  description = "Local port to reverse-proxy to.";
                };
              };

              # ── Wrapper Script ──
              createWrapper = mkOption {
                type = types.bool;
                default = true;
                description = "Create a dc-<name> wrapper script in the system PATH.";
              };
            };
          }
        )
      );
    };
  };

  config = lib.mkMerge [
    {
      mine.services.dockerCompose.enable = lib.mkDefault (enabledStacks != { });
    }
    (mkIf cfg.enable {
      assertions =
        let
          perStackAssertions = concatLists (
            mapAttrsToList (
              name: stackCfg:
              [
                {
                  assertion = (stackCfg.compose != null) != (stackCfg.composeFile != null);
                  message = "docker-compose stack '${name}': exactly one of compose or composeFile must be set.";
                }
                {
                  assertion =
                    stackCfg.agenix.envFile.file == null
                    || stackCfg.compose != null
                    || stackCfg.agenix.envFile.services != null;
                  message = "docker-compose stack '${name}': envFile.services must be set explicitly when using composeFile.";
                }
                {
                  assertion =
                    stackCfg.agenix.envFile.file == null
                    || stackCfg.agenix.envFile.services == null
                    || stackCfg.agenix.envFile.services != [ ];
                  message = "docker-compose stack '${name}': envFile.services is empty.";
                }
                {
                  assertion =
                    stackCfg.agenix.envFile.services == null
                    || stackCfg.compose == null
                    || lib.all (
                      s: builtins.hasAttr s (stackCfg.compose.services or { })
                    ) stackCfg.agenix.envFile.services;
                  message = "docker-compose stack '${name}': envFile.services references unknown service(s).";
                }
                {
                  assertion = !stackCfg.backup.enable || config.mine.services.restic.enable;
                  message = "docker-compose stack '${name}': backup.enable requires mine.services.restic.enable.";
                }
                {
                  assertion = !stackCfg.backup.enable || stackCfg.backup.paths != [ ];
                  message = "docker-compose stack '${name}': backup.enable is true but no paths specified.";
                }
                {
                  assertion =
                    stackCfg.gpu.services == [ ]
                    || stackCfg.compose == null
                    || lib.all (s: builtins.hasAttr s (stackCfg.compose.services or { })) stackCfg.gpu.services;
                  message = "docker-compose stack '${name}': gpu.services references unknown service(s).";
                }
                {
                  assertion =
                    stackCfg.autoUpdate.exclude == [ ]
                    || stackCfg.compose == null
                    || lib.all (s: builtins.hasAttr s (stackCfg.compose.services or { })) stackCfg.autoUpdate.exclude;
                  message = "docker-compose stack '${name}': autoUpdate.exclude references unknown service(s).";
                }
                {
                  assertion = !stackCfg.logging.enable || stackCfg.compose != null;
                  message = "docker-compose stack '${name}': logging.enable with composeFile is not supported (services can't be auto-discovered). Set logging directly in your compose file.";
                }
              ]
              ++ concatLists (
                mapAttrsToList (sName: sCfg: [
                  {
                    assertion =
                      stackCfg.compose == null
                      || lib.all (s: builtins.hasAttr s (stackCfg.compose.services or { })) sCfg.services;
                    message = "docker-compose stack '${name}': secret '${sName}' references unknown service(s).";
                  }
                  {
                    assertion = sCfg.services != [ ];
                    message = "docker-compose stack '${name}': secret '${sName}' has empty services list.";
                  }
                ]) stackCfg.agenix.secrets
              )
            ) enabledStacks
          );

          uniqueProjectNames =
            let
              allNames = mapAttrsToList (_: s: s.projectName) enabledStacks;
            in
            [
              {
                assertion = lib.length allNames == lib.length (lib.unique allNames);
                message = "docker-compose: duplicate projectName detected across enabled stacks.";
              }
            ];
        in
        perStackAssertions ++ uniqueProjectNames;

      virtualisation.docker.enable = true;

      age.secrets = lib.foldl' (acc: sc: acc // sc.ageSecrets) { } (builtins.attrValues stackConfigs);

      systemd.services = lib.foldl' (acc: sc: acc // sc.systemdService // sc.updateService) { } (
        builtins.attrValues stackConfigs
      );

      systemd.timers = lib.foldl' (acc: sc: acc // sc.updateTimer) { } (builtins.attrValues stackConfigs);

      systemd.tmpfiles.rules = concatLists (
        map (sc: sc.tmpfilesRules) (builtins.attrValues stackConfigs)
      );

      environment.systemPackages = concatLists (
        map (sc: sc.wrapperScript) (builtins.attrValues stackConfigs)
      );

      mine.services.restic.jobs = lib.mkIf (lib.any (sc: sc.backup.enable) (
        builtins.attrValues enabledStacks
      )) (lib.foldl' (acc: sc: acc // sc.resticJob) { } (builtins.attrValues stackConfigs));
    })
    (mkIf (lib.any (s: s.gpu.services != [ ]) (builtins.attrValues enabledStacks)) {
      hardware.nvidia-container-toolkit.enable = true;
      virtualisation.docker.daemon.settings.features.cdi = true;
    })
    (
      let
        tailscaleStacks = filterAttrs (_: s: s.tailscale.serviceName != null) enabledStacks;
        hasTailscale = tailscaleStacks != { };
        tailnet = cfg.tailscale.tailnet;
      in
      mkIf hasTailscale (
        let
          tsAuthKeyFile =
            if cfg.tailscale.authKeyFile != null then
              cfg.tailscale.authKeyFile
            else
              config.services.tailscale.authKeyFile;
        in
        {
          assertions = [
            {
              assertion = cfg.tailscale.tailnet != "";
              message = "docker-compose: tailscale.tailnet must be set when any stack uses tailscale.";
            }
            {
              assertion = config.services.tailscale.enable;
              message = "docker-compose: tailscale must be enabled (services.tailscale.enable) when any stack uses tailscale.";
            }
            {
              assertion = tsAuthKeyFile != null;
              message = "docker-compose: either tailscale.authKeyFile or services.tailscale.authKeyFile must be set when any stack uses tailscale.";
            }
          ];

          services.caddy = {
            enable = true;
            package = pkgs.caddy.withPlugins {
              plugins = [ "github.com/tailscale/caddy-tailscale@v0.0.0-20260106222316-bb080c4414ac" ];
              hash = "sha256-9CYQSdGAQwd1cmFuKT2RNzeiJ4DZoyrxvsLS4JDCFCY=";
            };
            globalConfig = ''
              tailscale {
                auth_key {env.TS_AUTHKEY}
              }
            '';
            virtualHosts = lib.mapAttrs' (
              _: stackCfg:
              lib.nameValuePair "${stackCfg.tailscale.serviceName}.${tailnet}.ts.net" {
                extraConfig = ''
                  bind tailscale/${stackCfg.tailscale.serviceName}
                  reverse_proxy localhost:${toString stackCfg.tailscale.port}
                '';
              }
            ) tailscaleStacks;
          };

          systemd.services.caddy.serviceConfig.ExecStartPre = [
            "+${pkgs.writeShellScript "caddy-ts-env" ''
              echo "TS_AUTHKEY=$(cat ${tsAuthKeyFile})" > /run/caddy-ts-env
              chmod 400 /run/caddy-ts-env
            ''}"
          ];
          systemd.services.caddy.serviceConfig.EnvironmentFile = [ "-/run/caddy-ts-env" ];
        }
      )
    )
  ];
}
