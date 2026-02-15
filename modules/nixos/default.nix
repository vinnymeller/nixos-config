{
  config,
  lib,
  vlib,
  ...
}:
let
  modules = vlib.readModuleFiles ./.;
  inherit (lib) mkEnableOption mkDefault;
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
        github-runners.enable = mkDefault cfg.selfhost;
        immich.enable = mkDefault cfg.selfhost;
        rsvpub.enable = mkDefault cfg.selfhost;
      };
      networking.enable = mkDefault true;
      nix.enable = mkDefault true;
    };
  };
}
