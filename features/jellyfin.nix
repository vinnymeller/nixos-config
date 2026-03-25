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
        default = "/data/jellyfin";
        description = "Base directory for Jellyfin data (config, cache, media).";
      };

    };
  nixos =
    {
      cfg,
      lib,
      resolveUser,
      ...
    }:
    let
      svc = resolveUser cfg.serviceUser;
    in
    {
      mine.services.dockerCompose.stacks.jellyfin = {
        autoUpdate.enable = true;
        gpu.services = [ "jellyfin" ];
        tailscale = {
          serviceName = "jellyfin";
          port = 8096;
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
            "${cfg.dataDir}/cache" = ug;
            "${cfg.dataDir}/config" = ug;
            "${cfg.dataDir}/media" = ug;
          };

        compose = {
          services = {
            jellyfin = {
              image = "jellyfin/jellyfin";
              container_name = "jellyfin";
              user = "${svc.uid}:${svc.gid}";
              restart = "unless-stopped";
              ports = [
                "8096:8096/tcp"
                "7359:7359/udp"
              ];
              volumes = [
                "${cfg.dataDir}/config:/config"
                "${cfg.dataDir}/cache:/cache"
                "${cfg.dataDir}/media:/media:ro"
              ];
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
      home.packages = [ pkgs.jellyfin-desktop ];
    };
}
