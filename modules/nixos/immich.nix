{
  lib,
  config,
  ...
}:

let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.mine.services.immich;
  mediaDir = "/data/immich";
  dbDir = "/var/lib/immich/postgres";
in
{
  options.mine.services.immich.enable = mkEnableOption "Immich media server";

  config = mkIf cfg.enable {
    mine.services.dockerCompose.stacks.immich = {
      gpu.services = [ "immich-machine-learning" ];
      autoUpdate.enable = false;
      agenix.envFile = {
        file = ../../secrets/vinnix/immich.age;
        services = [
          "immich-server"
          "database"
        ];
      };

      backup = {
        enable = true;
        paths = [ mediaDir ];
        exclude = [
          "${mediaDir}/thumbs"
          "${mediaDir}/encoded-video"
        ];
        extraBackupArgs = [ "--verbose" ];
      };

      storage.directories = {
        "${dbDir}" = {};
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
              "${mediaDir}:/data"
              "/etc/localtime:/etc/localtime:ro"
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
              "${dbDir}:/var/lib/postgresql"
            ];
            shm_size = "128mb";
          };
        };

        volumes.model-cache = { };
      };
    };
  };
}
