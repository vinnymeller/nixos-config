{ config, pkgs, ...}: {

  imports = [
    ./git.nix
    ./zsh.nix
    ./neovim.nix
  ];
  # Let home-manager manage itself
  programs.home-manager.enable = true;

  home.username = "vinny";
  home.homeDirectory = "/home/vinny";

  home.stateVersion = "22.11";

  home.packages = with pkgs; [
    gcc
    firefox
    # neovim
    htop
    libvirt
    nodejs-19_x
    dmenu
    nerdfonts
    neofetch
    qemu
    ripgrep
    rustup
    unzip
    virt-manager
    yubioath-flutter
    zsh-powerlevel10k
  ];

  programs.kitty = {
    enable = true;
    font = {
      name = "Jetbrains Mono";
      package = pkgs.jetbrains-mono;
    };
    extraConfig = "background_opacity	0.85";
  };


  home.shellAliases = {
      l = "ls -la";
      nvimt = "nvim -u ~/.nixdots/users/vinny/config/nvim/init.lua"; # nvim with editable config for testing
      nd = "nix develop -c $SHELL";
  };

  home.sessionVariables = {
     EDITOR = "nvim";
  };

}
