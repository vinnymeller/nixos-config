{
  config,
  lib,
  myUtils,
  ...
}:
let
  modules = myUtils.readModuleFiles ./.;
  inherit (lib) mkEnableOption mkIf mkDefault;
  cfg = config.uses;
in
{
  imports = modules;

  options = {
    uses = {
      selfhost = mkEnableOption "Enable self-hosted configuration.";
    };
  };

  config = {
    mine = {
      services = {
        github-runners = mkIf cfg.selfhost {
          enable = mkDefault true;
        };
      };
      networking.enable = mkDefault true;
    };
  };
}
