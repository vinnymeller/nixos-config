{
  options =
    {
      lib,
      ...
    }:
    {

      dataDir = lib.mkOption {
        type = lib.types.str;
        default = "/var/lib/paperless";
        description = "Base directory for Paperless-ngx data.";
      };

      secretFile = lib.mkOption {
        type = lib.types.path;
        description = "Age-encrypted .env with PAPERLESS_SECRET_KEY, POSTGRES_PASSWORD, PAPERLESS_DBPASS, PAPERLESS_ADMIN_USER, PAPERLESS_ADMIN_PASSWORD.";
      };

      port = lib.mkOption {
        type = lib.types.port;
        default = 8000;
      };

    };
  nixos =
    {
      cfg,
      config,
      pkgs,
      ...
    }:
    let
      appDataDir = "${cfg.dataDir}/data";
      consumeDir = "${cfg.dataDir}/consume";
      exportDir = "${cfg.dataDir}/export";
      mediaDir = "${cfg.dataDir}/media";
      postgresDir = "${cfg.dataDir}/postgres";
    in
    {
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
          paths = [ exportDir ];
          backupPrepareCommand = ''
            ${pkgs.docker}/bin/docker exec paperless-webserver python3 manage.py document_exporter ../export --compare-checksums --use-folder-prefix --split-manifest
          '';
        };

        storage.directories = {
          "${cfg.dataDir}" = { };
          "${appDataDir}" = { };
          "${consumeDir}" = { };
          "${exportDir}" = { };
          "${mediaDir}" = { };
          "${postgresDir}" = { };
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
                PAPERLESS_TIME_ZONE = config.time.timeZone;
                PAPERLESS_OCR_LANGUAGE = "eng";
              };
              volumes = [
                "${appDataDir}:/usr/src/paperless/data"
                "${mediaDir}:/usr/src/paperless/media"
                "${exportDir}:/usr/src/paperless/export"
                "${consumeDir}:/usr/src/paperless/consume"
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
                "${postgresDir}:/var/lib/postgresql"
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
  home =
    {
      pkgs,
      ...
    }:
    {
      xdg.desktopEntries = {

        paperless = {
          name = "Paperless-ngx";
          exec = "${pkgs.google-chrome}/bin/google-chrome-stable --app=https://paperless.vinnix.net";
          icon = "paperless-ngx";
          type = "Application";
        };
      };

    };
}
