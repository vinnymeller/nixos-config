{
  options =
    { lib, ... }:
    {
      mullvad = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable Mullvad VPN (wg-mv).";
        };
        secretFile = lib.mkOption {
          type = lib.types.path;
          description = "Path to the Mullvad WireGuard private key .age file.";
        };
        address = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [
            "10.69.64.78/32"
            "fc00:bbbb:bbbb:bb01::6:404d/128"
          ];
        };
        endpoint = lib.mkOption {
          type = lib.types.str;
          default = "45.134.140.130:51820";
        };
        publicKey = lib.mkOption {
          type = lib.types.str;
          default = "nvyBkaEXHwyPBAm8spGB0TFzf2W5wPAl8EEuJ0t+bzs=";
        };
      };
      airvpn = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable AirVPN (wg-air).";
        };
        secretFile = lib.mkOption {
          type = lib.types.path;
          description = "Path to the AirVPN WireGuard private key .age file.";
        };
        pskFile = lib.mkOption {
          type = lib.types.path;
          description = "Path to the AirVPN WireGuard preshared key .age file.";
        };
        address = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [
            "10.164.118.136/32"
            "fd7d:76ee:e68f:a993:a299:3b9a:79af:f098/128"
          ];
        };
        endpoint = lib.mkOption {
          type = lib.types.str;
          default = "68.235.35.253:1637";
        };
        publicKey = lib.mkOption {
          type = lib.types.str;
          default = "PyLCXAQT8KkM4T+dUsOQfn+Ub3pGxfGlxkIApuig+hk=";
        };
      };
    };

  nixos =
    {
      cfg,
      config,
      lib,
      ...
    }:
    lib.mkMerge [
      (lib.mkIf cfg.mullvad.enable {
        services.mullvad-vpn.enable = lib.mkDefault true;

        age.secrets.mullvad-wg-key = {
          file = cfg.mullvad.secretFile;
          mode = "0400";
        };

        networking.wg-quick.interfaces.wg-mv = {
          address = cfg.mullvad.address;
          privateKeyFile = config.age.secrets.mullvad-wg-key.path;
          table = "off";
          postUp = ''
            ip route add default dev wg-mv table 51820
            ip rule add from ${lib.head cfg.mullvad.address} table 51820
          ''
          + lib.optionalString config.services.tailscale.enable ''
            ip rule add iif tailscale0 lookup 51820 priority 5265
          '';
          postDown = ''
            ip rule del from ${lib.head cfg.mullvad.address} table 51820
          ''
          + lib.optionalString config.services.tailscale.enable ''
            ip rule del iif tailscale0 lookup 51820 priority 5265
          '';
          peers = [
            {
              publicKey = cfg.mullvad.publicKey;
              endpoint = cfg.mullvad.endpoint;
              allowedIPs = [
                "0.0.0.0/0"
                "::0/0"
              ];
            }
          ];
        };
      })

      (lib.mkIf cfg.airvpn.enable {
        age.secrets.airvpn-wg-key = {
          file = cfg.airvpn.secretFile;
          mode = "0400";
        };
        age.secrets.airvpn-wg-psk = {
          file = cfg.airvpn.pskFile;
          mode = "0400";
        };

        networking.wg-quick.interfaces.wg-air = {
          address = cfg.airvpn.address;
          privateKeyFile = config.age.secrets.airvpn-wg-key.path;
          table = "off";
          mtu = 1320;
          peers = [
            {
              publicKey = cfg.airvpn.publicKey;
              presharedKeyFile = config.age.secrets.airvpn-wg-psk.path;
              endpoint = cfg.airvpn.endpoint;
              allowedIPs = [
                "0.0.0.0/0"
                "::/0"
              ];
              persistentKeepalive = 15;
            }
          ];
        };
      })
    ];
}
