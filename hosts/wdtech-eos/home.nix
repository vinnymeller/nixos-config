{ inputs, outputs, pkgs, ... }:
let
    cust_pkgs = import ../../pkgs { inherit pkgs; };
in
{
    imports = [
        ../../modules/neovim
        ../../modules/zsh
        ../../modules/git
        ../../modules/tmux
        ../../modules/kitty
    ];


    nixpkgs.overlays = builtins.attrValues outputs.overlays;

    home.packages = with pkgs; [
        openvpn
        mesa
    ] ++ builtins.attrValues cust_pkgs;

    programs.direnv.enable = true;
    programs.direnv.nix-direnv.enable = true;

    home.username = "vinny";
    home.homeDirectory = "/home/vinny";
    home.stateVersion = "22.11";

    programs.home-manager.enable = true;

}
