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

  # direnv !
  programs.direnv.enable = true;
  programs.direnv.nix-direnv.enable = true;


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
    dunst
    feh
    lxde.lxsession
    nerdfonts
    neofetch
    osu-lazer
    qemu
    man-pages # linux man pages, goes with tlpi
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
      nb = "sudo nixos-rebuild --flake ~/.nixdots switch";
      cdots = "pushd ~/.nixdots";
  };

  home.sessionVariables = {
     EDITOR = "nvim";
  };

  home.file.".tmux.conf".source = ../../../../dotfiles/.tmux.conf;
  home.file.".config/qtile".source = ../../../../dotfiles/qtile;
  # home.file.".config/dunst".source = ../../../../dotfiles/dunst;
}
