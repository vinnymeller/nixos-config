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
    ;

  cfg = config.mine.services.paperless;
  dataDir = "/var/lib/paperless";
in
{
  options.mine.services.paperless = {
    enable = mkEnableOption "Paperless-ngx document management";
    secretFile = mkOption {
      type = types.path;
      description = "Age-encrypted .env with PAPERLESS_SECRET_KEY, POSTGRES_PASSWORD, PAPERLESS_DBPASS, PAPERLESS_ADMIN_USER, PAPERLESS_ADMIN_PASSWORD.";
    };
    port = mkOption {
      type = types.port;
      default = 8000;
    };
    timeZone = mkOption {
      type = types.str;
      default = "America/Chicago";
    };
  };

  config = mkIf cfg.enable {
    mine.services.dockerCompose.stacks.paperless = {
      autoUpdate.enable = false;

      agenix.envFile = {
        file = cfg.secretFile;
        services = [
          "webserver"
          "db"
        ];
      };

      tailscale = {
        serviceName = "paperless";
        port = cfg.port;
      };

      backup = {
        enable = true;
        paths = [ "${dataDir}/export" ];
        backupPrepareCommand = ''
          ${pkgs.docker}/bin/docker exec paperless-webserver python3 manage.py document_exporter ../export --compare-checksums --use-folder-prefix --split-manifest
        '';
      };

      storage.directories = {
        "${dataDir}" = { };
        "${dataDir}/data" = { };
        "${dataDir}/media" = { };
        "${dataDir}/export" = { };
        "${dataDir}/consume" = { };
        "${dataDir}/postgres" = { };
      };

      compose = {
        services = {
          webserver = {
            image = "ghcr.io/paperless-ngx/paperless-ngx:latest";
            container_name = "paperless-webserver";
            restart = "unless-stopped";
            ports = [ "${toString cfg.port}:8000" ];
            environment = {
              PAPERLESS_REDIS = "redis://broker:6379";
              PAPERLESS_DBHOST = "db";
              PAPERLESS_DBENGINE = "postgresql";
              PAPERLESS_DBNAME = "paperless";
              PAPERLESS_DBUSER = "paperless";
              PAPERLESS_URL = "https://paperless.${config.mine.services.dockerCompose.tailscale.customDomain}";
              PAPERLESS_TIME_ZONE = cfg.timeZone;
              PAPERLESS_OCR_LANGUAGE = "eng";
            };
            volumes = [
              "${dataDir}/data:/usr/src/paperless/data"
              "${dataDir}/media:/usr/src/paperless/media"
              "${dataDir}/export:/usr/src/paperless/export"
              "${dataDir}/consume:/usr/src/paperless/consume"
            ];
            depends_on = [
              "db"
              "broker"
            ];
          };

          db = {
            image = "docker.io/library/postgres:18";
            container_name = "paperless-db";
            restart = "unless-stopped";
            environment = {
              POSTGRES_DB = "paperless";
              POSTGRES_USER = "paperless";
            };
            volumes = [
              "${dataDir}/postgres:/var/lib/postgresql"
            ];
            healthcheck = {
              test = [
                "CMD-SHELL"
                "pg_isready -U paperless"
              ];
              interval = "10s";
              timeout = "5s";
              retries = 5;
            };
          };

          broker = {
            image = "docker.io/library/redis:8";
            container_name = "paperless-broker";
            restart = "unless-stopped";
            volumes = [
              "redisdata:/data"
            ];
            healthcheck = {
              test = [
                "CMD"
                "redis-cli"
                "ping"
              ];
            };
          };
        };

        volumes.redisdata = { };
      };
    };
  };
}
