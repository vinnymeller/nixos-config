{
  config,
  pkgs,
  inputs,
  outputs,
  ...
}: let
  cust_pkgs = import ../../../../pkgs {inherit pkgs;};
in {
  imports = [
    ../../../../programs/git
    ../../../../programs/zsh
    ../../../../programs/kitty
    ../../../../programs/ranger
    ../../../../programs/tmux
    ../../../../programs/zk
    outputs.myNixCats.homeModule
  ];
  # Let home-manager manage itself
  programs.home-manager.enable = true;

  nixCats = {
    enable = true;
    packageNames = ["nixCats"];
  };

  # direnv !
  programs.direnv.enable = true;
  programs.direnv.nix-direnv.enable = true;

  home.username = "vinny";
  home.homeDirectory = "/home/vinny";

  home.stateVersion = "22.11";

  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;
    maxCacheTtl = 10;
    maxCacheTtlSsh = 10;
    defaultCacheTtl = 10;
    defaultCacheTtlSsh = 10;
  };

  home.packages = with pkgs;
    [
      anki-bin
      chromium
      cinnamon.nemo-with-extensions
      cinnamon.xviewer
      dmenu
      dunst
      easyeffects
      feh
      flameshot
      gcc
      gnome.nautilus
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
      # osu-lazer-bin # re-add this when its working again
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
      master-pkgs.vesktop
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
