{ config, pkgs, ...}: {

  imports = [
    ../../../../modules/git
    ../../../../modules/zsh
    ../../../../modules/neovim
    ../../../../modules/kitty
    ../../../../modules/tmux
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
    rustup
    unzip
    virt-manager
    tmux
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

}
