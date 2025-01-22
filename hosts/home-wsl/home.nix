{
  pkgs,
  lib,
  outputs,
  ...
}:
let
  cust_pkgs = import ../../pkgs { inherit pkgs; };
in
{
  imports = [
    ../../programs/zsh
    ../../programs/git
    ../../programs/tmux
    ../../programs/kitty
    ../../programs/zk
    outputs.myNixCats.homeModule
  ];

  gitConfig.gpgSignDefault = false;

  nixCats = {
    enable = true;
    packageNames = [ "nixCats" ];
  };

  home.packages =
    with pkgs;
    [
      openvpn
      mesa
      kubectl
      helm
      nix-index
    ]
    ++ builtins.attrValues cust_pkgs;

  programs.direnv.enable = true;
  programs.direnv.nix-direnv.enable = true;

  home.username = "vinny";
  home.homeDirectory = lib.mkForce "/home/vinny";
  home.stateVersion = "24.05";

  programs.home-manager.enable = true;

  programs.zsh.sessionVariables = {
    TMUX_TMPDIR = "/tmp";
  };

  home.file.".config/nixpkgs".source = ../../dotfiles/nixpkgs;
}
