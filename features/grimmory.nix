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

      dataDir = lib.mkOption {
        type = lib.types.str;
        default = "/var/lib/grimmory";
        description = "Base directory for Grimmory data (books, bookdrop).";
      };

      secretFile = lib.mkOption {
        type = lib.types.path;
        description = "Age-encrypted .env file with DB_PASSWORD and MYSQL_ROOT_PASSWORD.";
      };

      port = lib.mkOption {
        type = lib.types.port;
        default = 6060;
      };

    };
  nixos =
    {
      cfg,
      config,
      resolveUser,
      ...
    }:
    let
      svc = resolveUser cfg.serviceUser;
      appDataDir = "${cfg.dataDir}/data";
      mariadbDir = "${cfg.dataDir}/mariadb";
      booksDir = "${cfg.dataDir}/books";
      bookdropDir = "${cfg.dataDir}/bookdrop";
    in
    {
      mine.services.dockerCompose.stacks.grimmory = {
        autoUpdate.enable = true;
        agenix.envFile.file = cfg.secretFile;
        tailscale = {
          serviceName = "grimmory";
          port = cfg.port;
        };

        backup = {
          enable = true;
          paths = [ cfg.dataDir ];
          exclude = [ mariadbDir ];
        };

        storage.directories =
          let
            ug = {
              owner = svc.uid;
              group = svc.gid;
            };
          in
          {
            "${cfg.dataDir}" = ug;
            "${appDataDir}" = ug;
            "${mariadbDir}" = ug;
            "${booksDir}" = ug;
            "${bookdropDir}" = ug;
          };

        compose = {
          services = {
            grimmory = {
              image = "ghcr.io/grimmory-tools/grimmory:latest";
              container_name = "booklore";
              restart = "unless-stopped";
              ports = [ "${toString cfg.port}:6060" ];
              environment = {
                USER_ID = svc.uid;
                GROUP_ID = svc.gid;
                DATABASE_URL = "jdbc:mariadb://booklore-mariadb:3306/booklore";
                DATABASE_USERNAME = "booklore";
                DISK_TYPE = "LOCAL";
              };
              volumes = [
                "${appDataDir}:/app/data"
                "${booksDir}:/books"
                "${bookdropDir}:/bookdrop"
              ];
              depends_on.mariadb.condition = "service_healthy";
            };

            mariadb = {
              image = "lscr.io/linuxserver/mariadb:11.4.8";
              container_name = "booklore-mariadb";
              restart = "unless-stopped";
              environment = {
                MYSQL_DATABASE = "booklore";
                MYSQL_USER = "booklore";
                PUID = svc.uid;
                PGID = svc.gid;
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
  home =
    {
      pkgs,
      ...
    }:
    {
      xdg.desktopEntries = {

        grimmory = {
          name = "Grimmory";
          exec = "${pkgs.google-chrome}/bin/google-chrome-stable --app=https://grimmory.vinnix.net";
          icon = "booklore";
          type = "Application";
        };
      };

    };
}
