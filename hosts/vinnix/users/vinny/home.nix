{
  config,
  pkgs,
  inputs,
  outputs,
  ...
}:
let
  cust_pkgs = import ../../../../pkgs { inherit pkgs; };
in
{
  imports = [
    ../../../../modules/home-manager
  ];
  # Let home-manager manage itself
  profile.vinny.enable = true;
  profile.vinny.hyprland = true;

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

  home.packages =
    with pkgs;
    [
      anki-bin
      chromium
      google-chrome
      nemo-with-extensions
      xviewer
      dmenu
      dunst
      easyeffects
      feh
      gcc
      discord
      nautilus
      gocryptfs
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
      nerd-fonts._0xproto
      # nix-index
      nix-init
      obs-studio
      osu-lazer-bin # re-add this when its working again
      pavucontrol
      pkg-config
      protonup-qt
      qemu
      rofi
      sbctl
      screenkey
      unzip
      virt-manager
      vlc
      yubioath-flutter
      zsh-powerlevel10k
      (lutris.override {
        extraPkgs = pkgs: [
          wine
        ];
      })
    ]
    ++ builtins.attrValues cust_pkgs;

  programs.command-not-found.enable = false;

  home.file.".config/nixpkgs".source = ../../../../dotfiles/nixpkgs;
  home.file.".Xresources".source = ../../../../dotfiles/.Xresources;
}
