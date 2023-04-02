{ config, pkgs, ... }: {
    home.packages = with pkgs; [
        ranger
        python3Packages.pillow
    ];

    home.shellAliases = {
        ranger = "ranger --confdir=~/.nixdots/dotfiles/ranger";
    };
}
