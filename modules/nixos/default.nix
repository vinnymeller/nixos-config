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
  imports = modules ++ vlib.mkFeatures ../../features;

  options = {
    profile = {
      selfhost = mkEnableOption "Enable self-hosted configuration.";
    };
  };

  config = {
    mine = {
      services = {
        github-runners.enable = mkDefault cfg.selfhost;
        restic.enable = mkDefault false;
      };
      networking.enable = mkDefault true;
    };
  };
}
