{ config, pkgs, ... }: {

    programs.tmux.enable = true;
    home.file.".tmux.conf".source = ../../dotfiles/.tmux.conf;

}
