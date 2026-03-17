{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.mine.networking;
in
{

  options.mine.networking = {
    enable = mkEnableOption "Enable networking configuration";
  };

  config = mkIf cfg.enable {

    networking.networkmanager = {
      enable = true;
      wifi.powersave = false;
    };

    environment.systemPackages = with pkgs; [
      networkmanagerapplet
    ];

    systemd.services.network-watchdog = {
      description = "Restart NetworkManager if internet is unreachable";
      after = [ "NetworkManager.service" ];
      wants = [ "NetworkManager.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "simple";
        Restart = "always";
        RestartSec = 10;
        StartLimitBurst = 5;
        StartLimitIntervalSec = 300;
        ExecStart = pkgs.writeShellScript "network-watchdog" ''
          set +e
          ping=${pkgs.iputils}/bin/ping
          check_internet() {
            $ping -c 2 -W 5 1.1.1.1 &>/dev/null ||
            $ping -c 2 -W 5 8.8.8.8 &>/dev/null ||
            $ping -c 2 -W 5 9.9.9.9 &>/dev/null
          }
          while true; do
            sleep 30
            if ! check_internet; then
              sleep 15
              if ! check_internet; then
                echo "Internet unreachable after two checks, restarting NetworkManager"
                systemctl restart NetworkManager
                sleep 60
              fi
            fi
          done
        '';
      };
    };

  };
}
