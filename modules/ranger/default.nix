{ config, pkgs, ... }: {

    home.file.".config/ranger".source = ../../dotfiles/ranger;

    home.packages = with pkgs; [
        ranger
    ];
}
