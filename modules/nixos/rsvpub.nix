{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.mine.services.rsvpub;
in
{

  imports = [
    inputs.rsvpub.nixosModules.default
  ];

  options.mine.services.rsvpub = {
    enable = mkEnableOption "Enable RSVPub service";
  };

  config = mkIf cfg.enable {

    services.rsvpub = {
      enable = true;
      package = inputs.rsvpub.packages.${pkgs.stdenv.hostPlatform.system}.default;
      host = "0.0.0.0";
      port = 7787;
      openFirewall = false;
    };

  };
}
