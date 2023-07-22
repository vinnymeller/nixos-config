{ pkgs, lib, ... }:
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

    home.packages = with pkgs; [
        openvpn
        mesa
        twm
    ] ++ builtins.attrValues cust_pkgs;

    programs.direnv.enable = true;
    programs.direnv.nix-direnv.enable = true;

    home.username = "vinny";
    home.homeDirectory = lib.mkForce "/home/vinny";
    home.stateVersion = "22.11";

    programs.home-manager.enable = true;

    programs.zsh.sessionVariables = {
        TMUX_TMPDIR = "/tmp";
    };

}
