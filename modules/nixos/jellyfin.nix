{
  lib,
  config,
  ...
}:

let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.mine.services.jellyfin;
  dataDir = "/data/jellyfin";
in
{
  options.mine.services.jellyfin.enable = mkEnableOption "Jellyfin media server";

  config = mkIf cfg.enable {
    mine.services.dockerCompose.stacks.jellyfin = {
      autoUpdate.enable = true;
      gpu.services = [ "jellyfin" ];
      tailscale = {
        serviceName = "jellyfin";
        port = 8096;
      };

      storage.directories = {
        "${dataDir}" = {
          owner = "1000";
          group = "1000";
        };
        "${dataDir}/config" = {
          owner = "1000";
          group = "1000";
        };
        "${dataDir}/cache" = {
          owner = "1000";
          group = "1000";
        };
        "${dataDir}/media" = {
          owner = "1000";
          group = "1000";
        };
      };

      compose = {
        services = {
          jellyfin = {
            image = "jellyfin/jellyfin";
            container_name = "jellyfin";
            user = "1000:1000";
            restart = "unless-stopped";
            ports = [
              "8096:8096/tcp"
              "7359:7359/udp"
            ];
            volumes = [
              "${dataDir}/config:/config"
              "${dataDir}/cache:/cache"
              "${dataDir}/media:/media:ro"
            ];
          };
        };
      };
    };
  };
}
