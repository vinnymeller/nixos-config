{
  options =
    { lib, ... }:
    {
      authKeyFile = lib.mkOption {
        type = lib.types.path;
        description = "Path to the Tailscale auth key .age file.";
      };
      exitNode = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Advertise this host as a Tailscale exit node.";
      };
      useRoutingFeatures = lib.mkOption {
        type = lib.types.str;
        default = "both";
      };
    };

  assertions =
    { features, lib, ... }:
    [
      {
        assertion = features.tailscale.exitNode -> features.vpn.mullvad.enable;
        message = "Tailscale exit node requires features.vpn.mullvad to be enabled for traffic routing.";
      }
    ];

  nixos =
    {
      cfg,
      config,
      lib,
      ...
    }:
    lib.mkMerge [
      {
        age.secrets.tailscale-authkey = {
          file = cfg.authKeyFile;
          mode = "0400";
        };

        services.tailscale = {
          enable = lib.mkDefault true;
          useRoutingFeatures = lib.mkDefault cfg.useRoutingFeatures;
          extraUpFlags = lib.optional cfg.exitNode "--advertise-exit-node";
          authKeyFile = config.age.secrets.tailscale-authkey.path;
        };

        networking.firewall = {
          checkReversePath = lib.mkDefault "loose";
          trustedInterfaces = [ "tailscale0" ];
          allowedUDPPorts = [ config.services.tailscale.port ];
        };

        systemd.services.tailscaled.serviceConfig.Environment = [
          "TS_DEBUG_FIREWALL_MODE=nftables"
        ];
      }

      (lib.mkIf cfg.exitNode {
        networking.nftables.enable = lib.mkDefault true;
        networking.nftables.tables.tailscale-exit = {
          family = "inet";
          content = ''
            chain forward {
              type filter hook forward priority filter + 1; policy accept;
              iifname "tailscale0" oifname "wg-mv" counter accept
              iifname "tailscale0" oifname "tailscale0" counter accept
              iifname "tailscale0" counter drop
            }
            chain nat {
              type nat hook postrouting priority srcnat; policy accept;
              oifname "wg-mv" masquerade
            }
          '';
        };
      })
    ];
}
