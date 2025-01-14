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
    outputs.myNixCats.homeModule
  ];

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
}
