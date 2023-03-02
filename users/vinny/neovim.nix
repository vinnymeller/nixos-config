{ config, pkgs, ...}: {

    programs.neovim.enable = true;
    home.file.".config/nvim".source = ./config/nvim;

}
