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

  };
}
