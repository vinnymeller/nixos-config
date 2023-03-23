{ config, pkgs, ...}: {

  imports = [
    ../../../../modules/git
    ../../../../modules/zsh
    ../../../../modules/neovim
    ../../../../modules/kitty
    # ../../../../modules/tmux
  ];
  # Let home-manager manage itself
  programs.home-manager.enable = true;

  home.username = "vinny";
  home.homeDirectory = "/home/vinny";

  home.stateVersion = "22.11";

  home.packages = with pkgs; [
    gcc
    firefox
    htop
    libvirt
    dmenu
    discord
    nerdfonts
    neofetch
    osu-lazer
    qemu
    pkg-config
    rustup
    tmux
    unzip
    virt-manager
    yubioath-flutter
    rofi
    spotify
    zsh-powerlevel10k
  ];

  home.shellAliases = {
      l = "ls -la";
      nvimt = "nvim -u ~/.nixdots/dotfiles/nvim/init.lua"; # nvim with editable config for testing
      nd = "nix develop -c $SHELL";
  };

  home.sessionVariables = {
     EDITOR = "nvim";
  };

  home.file.".tmux.conf".source = ../../../../dotfiles/.tmux.conf;
  # home.file.".config/qtile".source = ../../../../dotfiles/qtile;
}
