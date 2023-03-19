{ config, pkgs, ... }: {

    home.file.".tmux.conf".source = ../../dotfiles/.tmux.conf;

}
