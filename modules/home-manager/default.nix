{
  config,
  lib,
  vlib,
  ...
}:
let
  # utils = import ../../utils { inherit lib; };
  modules = vlib.readModuleFiles ./.;
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
        hyprland = mkEnableOption "Enable Hyprland config.";
      };
    };
    hmStandalone = mkEnableOption "Enable standalone home-manager configuration.";
  };

  config = {
    programs.home-manager.enable = true;
    home.file.".config/nixpkgs".source = ../../dotfiles/nixpkgs;
    mine = {
      git.enable = cfg.vinny.enable;
      hyprland.enable = cfg.vinny.hyprland;
      kitty.enable = cfg.vinny.enable;
      nix.enable = cfg.vinny.enable;
      nixpkgs.enable = mkIf config.hmStandalone true;
      pkgs.enable = cfg.vinny.enable;
      secrets.enable = cfg.vinny.enable;
      tmux.enable = cfg.vinny.enable;
      wsl.enable = cfg.vinny.wsl;
      zk.enable = cfg.vinny.enable;
      zsh.enable = cfg.vinny.enable;
    };
  };
}
