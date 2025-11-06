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
  home.stateVersion = "25.05";

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
      feh
      gcc
      # discord
      # vesktop
      gocryptfs
      htop
      libreoffice
      libvirt
      lxsession
      man-pages # linux man pages, goes with tlpi
      neofetch
      nerd-fonts._0xproto
      # nix-index
      nix-init
      obs-studio
      # osu-lazer-bin # re-add this when its working again
      (osu-lazer.override { nativeWayland = true; })
      pavucontrol
      pkg-config
      protonup-qt
      qemu
      sbctl
      screenkey
      unzip
      koreader
      virt-manager
      yubioath-flutter
      yubikey-manager
      zsh-powerlevel10k
      (lutris.override {
        extraPkgs = pkgs: [
          wine
        ];
      })
    ]
    ++ builtins.attrValues cust_pkgs;

  programs.vesktop.enable = true;
  programs.spotify-player.enable = true;

  programs.command-not-found.enable = false;

  home.file.".config/nixpkgs".source = ../../../../dotfiles/nixpkgs;
}
