{
  config,
  lib,
  vlib,
  ...
}:
let
  modules = vlib.readModuleFiles ./.;
  inherit (lib) mkEnableOption;
  cfg = config.profile;
in
{
  imports = modules ++ vlib.mkHmFeatures ../../features;

  options = {
    profile = {
      vinny = {
        enable = mkEnableOption "Enable Vinny's default configuration.";
      };
    };
  };

  config = {
    programs.home-manager.enable = true;
    mine = {
      pkgs.enable = cfg.vinny.enable;
      secrets.enable = cfg.vinny.enable;

    };
  };
}
