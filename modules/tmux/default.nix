{ config, pkgs, ... }: {

  programs.tmux.enable = true;
  programs.tmux.extraConfig = builtins.readFile ../../dotfiles/.tmux.conf;
  home.file.".config/twm/twm.yaml".source = ../../dotfiles/twm/twm.yaml;

}
