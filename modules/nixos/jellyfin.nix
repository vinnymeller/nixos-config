{
  lib,
  config,
  ...
}:

let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.mine.services.jellyfin;
  dataDir = "/var/lib/jellyfin";
in
{
  options.mine.services.jellyfin.enable = mkEnableOption "Jellyfin media server";

  config = mkIf cfg.enable {
    mine.services.dockerCompose.stacks.jellyfin = {
      autoUpdate.enable = true;
      gpu.enable = true;
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

    systemd.tmpfiles.rules = [
      "d ${dataDir} 0755 1000 1000 -"
      "d ${dataDir}/config 0755 1000 1000 -"
      "d ${dataDir}/cache 0755 1000 1000 -"
      "d ${dataDir}/media 0755 1000 1000 -"
    ];
  };
}
