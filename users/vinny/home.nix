{ config, pkgs, ...}: {

  imports = [
    ./git.nix
    ./zsh.nix
    ./neovim.nix
    ./kitty.nix
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
    qemu
    rustup
    unzip
    virt-manager
    yubioath-flutter
    rofi
    zsh-powerlevel10k
  ];

  home.shellAliases = {
      l = "ls -la";
      nvimt = "nvim -u ~/.nixdots/users/vinny/config/nvim/init.lua"; # nvim with editable config for testing
      nd = "nix develop -c $SHELL";
  };

  home.sessionVariables = {
     EDITOR = "nvim";
  };

}
