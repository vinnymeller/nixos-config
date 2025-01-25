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
    ../../hm
    outputs.myNixCats.homeModule
  ];

  mine = {
    git = {
      enable = true;
      gpgSignDefault = false;
    };
    kitty.enable = true;
    tmux.enable = true;
    wslu.enable = true;
    zk.enable = true;
    zsh = {
      enable = true;
      autoStartTmux = false;
    };
  };

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

  home.username = "vinny";
  home.homeDirectory = lib.mkForce "/home/vinny";
  home.stateVersion = "24.05";
}
