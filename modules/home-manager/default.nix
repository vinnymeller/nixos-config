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
  imports = modules;

  options = {
    profile = {
      vinny = {
        enable = mkEnableOption "Enable Vinny's default configuration.";
        wsl = mkEnableOption "Enable WSL configuration.";
        hyprland = mkEnableOption "Enable Hyprland config.";
      };
    };
  };

  config = {
    programs.home-manager.enable = true;
    mine = {
      git.enable = cfg.vinny.enable;
      hyprland.enable = cfg.vinny.hyprland;
      kitty.enable = cfg.vinny.enable;
      nix.enable = cfg.vinny.enable;
      pkgs.enable = cfg.vinny.enable;
      secrets.enable = cfg.vinny.enable;
      ssh.enable = cfg.vinny.enable;
      tmux.enable = cfg.vinny.enable;
      wsl.enable = cfg.vinny.wsl;
      zk.enable = cfg.vinny.enable;
      zsh.enable = cfg.vinny.enable;
    };
  };
}
