{
  config,
  lib,
  ...
}:
let
  utils = import ../../utils { inherit lib; };
  modules = utils.readModuleFiles ./.;
  inherit (lib) mkEnableOption mkIf;
  cfg = config.profile;
in
{
  imports = modules;

  options = {
    profile = {
      vinny = {
        enable = mkEnableOption "Enable Vinny's default configuration.";
        wsl = mkEnableOption "Enable WSL configuration.";
      };
    };
    hmStandalone = mkEnableOption "Enable standalone home-manager configuration.";
  };

  config = {
    programs.home-manager.enable = true;
    home.file.".config/nixpkgs".source = ../../dotfiles/nixpkgs;
    mine = {
      git.enable = cfg.vinny.enable;
      kitty.enable = cfg.vinny.enable;
      nix.enable = cfg.vinny.enable;
      nixpkgs.enable = mkIf config.hmStandalone true;
      nvim.enable = cfg.vinny.enable;
      pkgs.enable = cfg.vinny.enable;
      tmux.enable = cfg.vinny.enable;
      wsl.enable = cfg.vinny.wsl;
      zk.enable = cfg.vinny.enable;
      zsh.enable = cfg.vinny.enable;
    };
  };
}
