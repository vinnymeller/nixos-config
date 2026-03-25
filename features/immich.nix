{
  options =
    {
      cfg,
      lib,
      ...
    }:
    {
      serviceUser = lib.mkOption {
        type = lib.types.str;
        default = builtins.head cfg.users;
      };

      mediaDir = lib.mkOption {
        type = lib.types.str;
        default = "/data/immich";
        description = "Directory to store media files (photos, videos).";
      };

      dbDir = lib.mkOption {
        type = lib.types.str;
        default = "/var/lib/immich/postgres";
      };

      secretFile = lib.mkOption {
        type = lib.types.path;
        description = "Age-encrypted .env with DB_PASSWORD.";
      };

    };
  nixos =
    {
      cfg,
      ...
    }:
    {
      mine.services.dockerCompose.stacks.immich = {
        gpu.services = [ "immich-machine-learning" ];
        autoUpdate.enable = false;
        tailscale = {
          serviceName = "immich";
          port = 2283;
        };
        agenix.envFile = {
          file = cfg.secretFile;
          services = [
            "immich-server"
            "database"
          ];
        };

        backup = {
          enable = true;
          paths = [ cfg.mediaDir ];
          exclude = [
            "${cfg.mediaDir}/thumbs"
            "${cfg.mediaDir}/encoded-video"
          ];
          extraBackupArgs = [ "--verbose" ];
        };

        storage.directories = {
          "${cfg.dbDir}" = { };
          "${cfg.mediaDir}" = { };
        };

        compose = {
          services = {
            immich-server = {
              image = "ghcr.io/immich-app/immich-server:release";
              container_name = "immich_server";
              restart = "always";
              ports = [ "2283:2283" ];
              environment = {
                DB_HOSTNAME = "database";
                DB_USERNAME = "immich";
                DB_DATABASE_NAME = "immich";
                REDIS_HOSTNAME = "redis";
              };
              volumes = [
                "${cfg.mediaDir}:/data"
              ];
              depends_on = [
                "redis"
                "database"
              ];
            };

            immich-machine-learning = {
              image = "ghcr.io/immich-app/immich-machine-learning:release-cuda";
              container_name = "immich_machine_learning";
              restart = "always";
              volumes = [ "model-cache:/cache" ];
            };

            redis = {
              image = "docker.io/valkey/valkey:9";
              container_name = "immich_redis";
              restart = "always";
              healthcheck = {
                test = [
                  "CMD"
                  "redis-cli"
                  "ping"
                ];
              };
            };

            database = {
              image = "ghcr.io/immich-app/postgres:18-vectorchord0.5.3-pgvector0.8.1";
              container_name = "immich_postgres";
              restart = "always";
              environment = {
                POSTGRES_USER = "immich";
                POSTGRES_DB = "immich";
                POSTGRES_INITDB_ARGS = "--data-checksums";
              };
              volumes = [
                "${cfg.dbDir}:/var/lib/postgresql"
              ];
              shm_size = "128mb";
            };
          };

          volumes.model-cache = { };
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

        immich = {
          name = "Immich";
          exec = "${pkgs.google-chrome}/bin/google-chrome-stable --app=https://immich.vinnix.net";
          icon = "immich";
          type = "Application";
        };
      };
    };
}
