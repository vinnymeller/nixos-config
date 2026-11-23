# The *arr stack: automatic TV/movie downloading into the Jellyfin library.
#
#   seerr      requests UI (friends sign in with their Jellyfin accounts)
#   sonarr     TV:     watches for wanted episodes, grabs, imports into tv/
#   radarr     movies: same, into movies/
#   prowlarr   indexer list, synced into sonarr + radarr
#   qbittorrent  the downloader, *inside* gluetun's network namespace
#   gluetun    WireGuard tunnel to AirVPN + kill switch: qbittorrent has no
#              route to the internet except through the tunnel
#   recyclarr  keeps sonarr/radarr quality profiles synced to TRaSH Guides
#
# Layout. Downloads live next to the library on the same filesystem, and
# sonarr/radarr see both through ONE bind mount, so imports are instant
# hardlinks (a finished torrent keeps seeding at no extra disk cost). Two
# separate bind mounts would break this: link(2) refuses to cross mount
# points even on the same filesystem.
#
#   host <mediaDir>/          sonarr/radarr: /data     jellyfin: /media (ro)
#     movies/                 /data/movies             /media/movies
#     tv/                     /data/tv                 /media/tv
#     torrents/{movies,tv}/   /data/torrents           (no library points here)
#
# qbittorrent mounts only torrents/, at the same /data/torrents path, so no
# remote path mappings are needed.
{
  options =
    {
      cfg,
      config,
      lib,
      ...
    }:
    {
      serviceUser = lib.mkOption {
        type = lib.types.str;
        default = builtins.head cfg.users;
        description = "User the containers run as; must be able to write mediaDir.";
      };

      mediaDir = lib.mkOption {
        type = lib.types.str;
        default = "${config.features.jellyfin.dataDir}/media";
        description = "Jellyfin library root (holds movies/ and tv/). torrents/ is created inside it.";
      };

      configDir = lib.mkOption {
        type = lib.types.str;
        default = "/var/lib/arr";
        description = "Per-app config + SQLite databases (backed up with restic).";
      };

      secretFile = lib.mkOption {
        type = lib.types.path;
        description = ''
          Age-encrypted .env pinning the API keys, so recyclarr (and you,
          wiring the apps together) know them up front:
            SONARR__AUTH__APIKEY=<32 hex>
            RADARR__AUTH__APIKEY=<32 hex>
        '';
      };

      vpnConfigFile = lib.mkOption {
        type = lib.types.path;
        description = ''
          Age-encrypted WireGuard config (wg0.conf) for a DEDICATED AirVPN
          device, from AirVPN's Config Generator. Endpoint must be an IP, not
          a hostname. Do not reuse the wg-air device: one AirVPN key can't hold
          two tunnels at once.
        '';
      };

      forwardedPort = lib.mkOption {
        type = lib.types.nullOr lib.types.port;
        default = null;
        description = ''
          AirVPN forwarded port (Client Area -> Ports), assigned to the arr
          device. qBittorrent listens on it and gluetun opens it on the tunnel.
          null = no port forward: downloads still work, with fewer peers.
        '';
      };
    };

  nixos =
    {
      cfg,
      config,
      lib,
      pkgs,
      resolveUser,
      ...
    }:
    let
      svc = resolveUser cfg.serviceUser;
      ug = {
        owner = svc.uid;
        group = svc.gid;
      };
      lsio = {
        PUID = svc.uid;
        PGID = svc.gid;
      };

      torrentsDir = "${cfg.mediaDir}/torrents";
      appDir = name: "${cfg.configDir}/${name}";

      # Loopback host ports (Caddy fronts them on the tailnet). qBittorrent's
      # WebUI is moved off the default 8080, which dev servers like to take.
      ports = {
        seerr = 5055;
        sonarr = 8989;
        radarr = 7878;
        prowlarr = 9696;
        qbittorrent = 8090;
      };

      jellyfinStack = config.mine.services.dockerCompose.stacks.jellyfin;
      jellyfinNetwork = "${jellyfinStack.projectName}_default";

      # First-run qBittorrent settings; only written when no config exists yet,
      # after that the WebUI owns the file. Without it qBittorrent would save
      # into an unmounted /downloads inside the container.
      #  - Automatic torrent management on: sonarr/radarr's categories (tv,
      #    movies) land in /data/torrents/<category>.
      #  - Bound to gluetun's tunnel interface: a second kill switch behind
      #    gluetun's firewall.
      qbitSeedConf = pkgs.writeText "qBittorrent.conf" ''
        [LegalNotice]
        Accepted=true

        [BitTorrent]
        Session\DefaultSavePath=/data/torrents
        Session\TempPathEnabled=false
        Session\DisableAutoTMMByDefault=false
        Session\Interface=tun0
        Session\InterfaceName=tun0

        [Preferences]
        WebUI\Address=*
        WebUI\ServerDomains=*
      '';

      # Quality, two profiles per app (all TRaSH "Combined" variants):
      #  - WEB (the default): 4K WEB releases when they exist, 1080p WEB
      #    otherwise; never Blu-ray rips or remuxes.
      #  - Remux, opt-in per movie/series: same WEB fallbacks, but keeps
      #    upgrading until it lands a remux (4K preferred). Radarr's variant
      #    also passes through Blu-ray encodes on the way up. 4K remuxes run
      #    ~50-80 GB per movie.
      # recyclarr also syncs each profile's default custom-format groups
      # (unwanted formats like BR-DISK/LQ/upscales, HDR scoring, streaming-
      # service tiers). Added on top: a penalty for Dolby Vision releases with
      # no HDR10 fallback, which only play correctly on DV-capable screens.
      # The group's TRaSH include list covers both profiles, so `add` with no
      # assign_scores_to applies it to each.
      recyclarrConfig = pkgs.writeText "recyclarr.yml" ''
        sonarr:
          sonarr:
            base_url: http://sonarr:${toString ports.sonarr}
            api_key: !env_var SONARR__AUTH__APIKEY
            delete_old_custom_formats: true
            quality_definition:
              type: series
            quality_profiles:
              - trash_id: c4cadd6b35b95f62c3d47a408e53e2f7 # WEB-2160p (Combined)
                reset_unmatched_scores:
                  enabled: true
              - trash_id: 911df0e05a395c19d8b3efc76a7467c1 # Remux 2160p (Combined)
                reset_unmatched_scores:
                  enabled: true
            custom_format_groups:
              add:
                - trash_id: d776a1ea912a117d66d83b880ff2055d # [HDR Formats] DV (w/o HDR fallback)
            media_naming:
              series: jellyfin-tvdb
              season: default
              episodes:
                rename: true
                standard: default
                daily: default
                anime: default

        radarr:
          radarr:
            base_url: http://radarr:${toString ports.radarr}
            api_key: !env_var RADARR__AUTH__APIKEY
            delete_old_custom_formats: true
            quality_definition:
              type: movie
            quality_profiles:
              - trash_id: 05fbf054ac8ad0303335026cc2632f1a # WEBDL 2160p (Combined)
                reset_unmatched_scores:
                  enabled: true
              - trash_id: d1d310673359205736b4b84acd5ea8c8 # Remux 2160p (Combined)
                reset_unmatched_scores:
                  enabled: true
            custom_format_groups:
              add:
                - trash_id: 7fc2751eef7e6bdc70b74136e5e35c76 # [HDR Formats] DV (w/o HDR fallback)
            media_naming:
              folder: jellyfin-tmdb
              movie:
                rename: true
                standard: jellyfin-tmdb
      '';
    in
    {
      # Here rather than in the feature's `assertions` hook, which also runs
      # under home-manager where these NixOS-only options are unset.
      assertions = [
        {
          assertion = config.features.jellyfin.enable;
          message = "features.arr imports into the Jellyfin library and joins its network; enable features.jellyfin.";
        }
        {
          assertion = builtins.pathExists cfg.vpnConfigFile;
          message = ''
            features.arr.vpnConfigFile (${toString cfg.vpnConfigFile}) does not exist.
            Create a new device in AirVPN's client area, generate a WireGuard config for it
            (Endpoint as an IP), then: ragenix -e secrets/vinnix/arr-wg0.conf.age  and paste it in.
          '';
        }
      ];

      mine.services.dockerCompose.stacks.arr = {
        autoUpdate.enable = true;

        # seerr joins jellyfin's compose network to reach http://jellyfin:8096,
        # so that network has to exist first.
        afterUnits = [ "docker-compose-${jellyfinStack.projectName}.service" ];
        requiresUnits = [ "docker-compose-${jellyfinStack.projectName}.service" ];

        tailscale.services = lib.mapAttrs (_: port: { inherit port; }) ports;

        agenix = {
          envFile = {
            file = cfg.secretFile;
            services = [
              "sonarr"
              "radarr"
              "recyclarr"
            ];
          };
          # gluetun reads key, preshared key, address and endpoint from here.
          secrets.wg0 = {
            file = cfg.vpnConfigFile;
            containerPath = "/run/secrets/wg0.conf";
            services = [ "gluetun" ];
          };
        };

        backup = {
          enable = true;
          paths = [ cfg.configDir ];
          exclude = [
            "${cfg.configDir}/*/logs"
            "${cfg.configDir}/*/MediaCover"
            "${cfg.configDir}/recyclarr/repositories"
            "${cfg.configDir}/recyclarr/cache"
          ];
        };

        storage.directories = {
          "${cfg.configDir}" = ug // {
            mode = "0700";
          };
          "${torrentsDir}" = ug;
          "${torrentsDir}/movies" = ug;
          "${torrentsDir}/tv" = ug;
        }
        // lib.genAttrs (map appDir [
          "sonarr"
          "radarr"
          "prowlarr"
          "qbittorrent"
          "qbittorrent/qBittorrent"
          "seerr"
          "recyclarr"
        ]) (_: ug);

        compose = {
          networks.jellyfin = {
            external = true;
            name = jellyfinNetwork;
          };

          services = {
            gluetun = {
              image = "qmcgaw/gluetun:v3";
              container_name = "gluetun";
              restart = "unless-stopped";
              cap_add = [ "NET_ADMIN" ];
              devices = [ "/dev/net/tun:/dev/net/tun" ];
              # qbittorrent shares this network namespace, so its WebUI is
              # published here. Other containers reach it as gluetun:<port>.
              ports = [ "${toString ports.qbittorrent}:${toString ports.qbittorrent}" ];
              environment = {
                VPN_SERVICE_PROVIDER = "custom";
                VPN_TYPE = "wireguard";
                VPN_INTERFACE = "tun0";
                # Matches wg-air, which is known to work on this network.
                WIREGUARD_MTU = "1320";
              }
              // lib.optionalAttrs (cfg.forwardedPort != null) {
                FIREWALL_VPN_INPUT_PORTS = toString cfg.forwardedPort;
              };
            };

            qbittorrent = {
              image = "lscr.io/linuxserver/qbittorrent:latest";
              container_name = "qbittorrent";
              restart = "unless-stopped";
              network_mode = "service:gluetun";
              # Only start once the tunnel is up; restart if gluetun is
              # recreated, since its old network namespace goes away.
              depends_on.gluetun = {
                condition = "service_healthy";
                restart = true;
              };
              environment =
                lsio
                // {
                  WEBUI_PORT = toString ports.qbittorrent;
                }
                // lib.optionalAttrs (cfg.forwardedPort != null) {
                  TORRENTING_PORT = toString cfg.forwardedPort;
                };
              volumes = [
                "${appDir "qbittorrent"}:/config"
                "${torrentsDir}:/data/torrents"
              ];
            };

            sonarr = {
              image = "lscr.io/linuxserver/sonarr:latest";
              container_name = "sonarr";
              restart = "unless-stopped";
              ports = [ "${toString ports.sonarr}:8989" ];
              environment = lsio;
              volumes = [
                "${appDir "sonarr"}:/config"
                "${cfg.mediaDir}:/data"
              ];
            };

            radarr = {
              image = "lscr.io/linuxserver/radarr:latest";
              container_name = "radarr";
              restart = "unless-stopped";
              ports = [ "${toString ports.radarr}:7878" ];
              environment = lsio;
              volumes = [
                "${appDir "radarr"}:/config"
                "${cfg.mediaDir}:/data"
              ];
            };

            prowlarr = {
              image = "lscr.io/linuxserver/prowlarr:latest";
              container_name = "prowlarr";
              restart = "unless-stopped";
              ports = [ "${toString ports.prowlarr}:9696" ];
              environment = lsio;
              volumes = [ "${appDir "prowlarr"}:/config" ];
            };

            seerr = {
              image = "ghcr.io/seerr-team/seerr:v3";
              container_name = "seerr";
              init = true;
              user = "${svc.uid}:${svc.gid}";
              restart = "unless-stopped";
              ports = [ "${toString ports.seerr}:5055" ];
              networks = [
                "default"
                "jellyfin"
              ];
              volumes = [ "${appDir "seerr"}:/app/config" ];
            };

            recyclarr = {
              image = "ghcr.io/recyclarr/recyclarr:8";
              container_name = "recyclarr";
              user = "${svc.uid}:${svc.gid}";
              restart = "unless-stopped";
              depends_on = [
                "sonarr"
                "radarr"
              ];
              volumes = [
                "${appDir "recyclarr"}:/config"
                "${recyclarrConfig}:/config/recyclarr.yml:ro"
              ];
            };
          };
        };
      };

      systemd.services."docker-compose-arr".preStart = ''
        conf=${appDir "qbittorrent"}/qBittorrent/qBittorrent.conf
        if [ ! -e "$conf" ]; then
          install -m 0600 -o ${svc.uid} -g ${svc.gid} ${qbitSeedConf} "$conf"
        fi
      '';
    };
}
