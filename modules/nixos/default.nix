{
  config,
  lib,
  vlib,
  ...
}:
let
  modules = vlib.readModuleFiles ./.;
  inherit (lib) mkEnableOption mkIf mkDefault;
  cfg = config.profile;
in
{
  imports = modules;

  options = {
    profile = {
      selfhost = mkEnableOption "Enable self-hosted configuration.";
    };
  };

  config = {
    mine = {
      gpg.enable = mkDefault true;
      ssh.enable = mkDefault true;
      services = {
        github-runners = mkIf cfg.selfhost {
          enable = mkDefault true;
        };
        rsvpub = mkIf cfg.selfhost {
          enable = mkDefault true;
        };
      };
      networking.enable = mkDefault true;
      nix.enable = mkDefault true;
    };
  };
}
