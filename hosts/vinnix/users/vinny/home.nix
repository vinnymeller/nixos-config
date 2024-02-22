{
  config,
  pkgs,
  ...
}: let
  cust_pkgs = import ../../../../pkgs {inherit pkgs;};
in {
  imports = [
    ../../../../programs/git
    ../../../../programs/zsh
    ../../../../programs/neovim
    ../../../../programs/kitty
    ../../../../programs/ranger
    ../../../../programs/tmux
    ../../../../programs/zk
  ];
  # Let home-manager manage itself
  programs.home-manager.enable = true;

  # direnv !
  programs.direnv.enable = true;
  programs.direnv.nix-direnv.enable = true;

  home.username = "vinny";
  home.homeDirectory = "/home/vinny";

  home.stateVersion = "22.11";

  home.packages = with pkgs;
    [
      osu-lazer-bin # re-add this when its working again
      anki-bin
      chromium
      cinnamon.nemo-with-extensions
      cinnamon.xviewer
      discord
      dmenu
      dunst
      easyeffects
      feh
      flameshot
      gcc
      gocryptfs
      gromit-mpx
      htop
      inkscape
      kompose
      kubectl
      kubernetes-helm
      libreoffice
      libvirt
      lxde.lxsession
      man-pages # linux man pages, goes with tlpi
      mullvad-vpn
      neofetch
      nerdfonts
      nix-index
      nix-init
      nix-init
      obs-studio
      obsidian
      pavucontrol
      pkg-config
      popcorntime
      protonup-qt
      qemu
      rofi
      sbctl
      screenkey
      slack
      spotify
      unzip
      virt-manager
      vlc
      yubioath-flutter
      zsh-powerlevel10k
    ]
    ++ builtins.attrValues cust_pkgs;

  programs.command-not-found.enable = false;
  programs.nix-index = {
    enable = true;
    enableZshIntegration = true;
  };

  home.file.".config/qtile".source = ../../../../dotfiles/qtile;
  home.file.".config/nixpkgs".source = ../../../../dotfiles/nixpkgs;
  home.file.".Xresources".source = ../../../../dotfiles/.Xresources;
}
