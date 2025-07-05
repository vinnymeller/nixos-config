{
  config,
  lib,
  ...
}:
let
  utils = import ../../utils { inherit lib; };
  modules = utils.readModuleFiles ./.;
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
      secrets.enable = mkDefault true;
      services = {
        cloudflared = mkIf cfg.selfhost {
          enable = mkDefault true;
          moves.enable = mkDefault true;
        };
        github-runners = mkIf cfg.selfhost {
          enable = mkDefault true;
        };
      };
    };

  };
}
