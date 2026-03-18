{
  config,
  lib,
  ...
}:

let
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;

  cfg = config.mine.services.booklore;
in
{
  options.mine.services.booklore = {
    enable = mkEnableOption "Booklore digital library";
    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/booklore";
    };
    booksDir = mkOption {
      type = types.str;
      default = "/var/lib/booklore/books";
    };
    bookdropDir = mkOption {
      type = types.str;
      default = "/var/lib/booklore/bookdrop";
    };
    port = mkOption {
      type = types.port;
      default = 6060;
    };
    secretFile = mkOption {
      type = types.path;
      description = "Age-encrypted .env with DB_PASSWORD and MYSQL_ROOT_PASSWORD.";
    };
    timeZone = mkOption {
      type = types.str;
      default = "America/Chicago";
    };
    uid = mkOption {
      type = types.int;
      default = 1000;
    };
    gid = mkOption {
      type = types.int;
      default = 1000;
    };
  };

  config = mkIf cfg.enable {
    mine.services.dockerCompose.stacks.booklore = {
      autoUpdate.enable = true;
      agenix.envFile.file = cfg.secretFile;
      tailscale = {
        serviceName = "booklore";
        port = cfg.port;
      };

      backup = {
        enable = true;
        paths = [ cfg.dataDir ];
        exclude = [ "${cfg.dataDir}/mariadb" ];
      };

      storage.directories =
        let
          ug = {
            owner = toString cfg.uid;
            group = toString cfg.gid;
          };
        in
        {
          "${cfg.dataDir}" = ug;
          "${cfg.dataDir}/data" = ug;
          "${cfg.dataDir}/mariadb" = ug;
          "${cfg.booksDir}" = ug;
          "${cfg.bookdropDir}" = ug;
        };

      compose = {
        services = {
          booklore = {
            image = "ghcr.io/booklore-app/booklore:latest";
            container_name = "booklore";
            restart = "unless-stopped";
            ports = [ "${toString cfg.port}:6060" ];
            environment = {
              APP_USER_ID = toString cfg.uid;
              APP_GROUP_ID = toString cfg.gid;
              TZ = cfg.timeZone;
              DATABASE_URL = "jdbc:mariadb://booklore-mariadb:3306/booklore";
              DB_USER = "booklore";
              DISK_TYPE = "LOCAL";
            };
            volumes = [
              "${cfg.dataDir}/data:/app/data"
              "${cfg.booksDir}:/books"
              "${cfg.bookdropDir}:/bookdrop"
            ];
            depends_on.mariadb.condition = "service_healthy";
          };

          mariadb = {
            image = "lscr.io/linuxserver/mariadb:11.4.5";
            container_name = "booklore-mariadb";
            restart = "unless-stopped";
            environment = {
              MYSQL_DATABASE = "booklore";
              MYSQL_USER = "booklore";
              PUID = toString cfg.uid;
              PGID = toString cfg.gid;
              TZ = cfg.timeZone;
            };
            volumes = [
              "${cfg.dataDir}/mariadb:/config"
            ];
            healthcheck = {
              test = [
                "CMD"
                "mariadb-admin"
                "ping"
                "-h"
                "localhost"
              ];
              interval = "10s";
              timeout = "5s";
              retries = 5;
            };
          };
        };
      };
    };
  };
}
