{ config, pkgs, ...}: {

    programs.neovim.enable = true;
    home.file.".config/nvim".source = ./config/nvim;


    home.packages = with pkgs; [
        ripgrep
        nodejs-19_x
    ];

}
