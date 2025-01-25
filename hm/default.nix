{
  config,
  lib,
  ...
}:
let
  dir = ./modules;
  modules = lib.pipe (builtins.readDir dir) [
    (lib.filterAttrs (_: type: type == "regular"))
    builtins.attrNames
    (builtins.filter (lib.hasSuffix ".nix"))
    (builtins.map (filename: dir + "/${filename}"))
  ];
  inherit (lib) mkEnableOption;
  cfg = config.profile;
in
{
  imports = modules;

  options.profile = {
    vinny = {
      enable = mkEnableOption "Enable Vinny's default configuration.";
      wsl = mkEnableOption "Enable WSL configuration.";
    };
  };
  config = {
    programs.home-manager.enable = true;
    home.file.".config/nixpkgs".source = ../dotfiles/nixpkgs;
    mine = {
      git.enable = cfg.vinny.enable;
      kitty.enable = cfg.vinny.enable;
      nix.enable = cfg.vinny.enable;
      nvim.enable = cfg.vinny.enable;
      pkgs.enable = cfg.vinny.enable;
      tmux.enable = cfg.vinny.enable;
      wsl.enable = cfg.vinny.wsl;
      zk.enable = cfg.vinny.enable;
      zsh.enable = cfg.vinny.enable;
    };
  };
}
