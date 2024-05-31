{ config, pkgs, ... }:
{

  programs.tmux.enable = true;
  programs.tmux.extraConfig = builtins.readFile ../../dotfiles/.tmux.conf;
}
