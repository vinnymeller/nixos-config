{ pkgs, ... }:
{
  imports = [
    ../../../../modules/home-manager
  ];
  home.stateVersion = "25.11";

  home.packages = with pkgs; [
    gcc
    discord-canary
    gocryptfs
    htop
    libvirt
    lxsession
    man-pages # linux man pages, goes with tlpi
    fastfetch
    nerd-fonts._0xproto
    nix-init
    obs-studio
    (master-pkgs.osu-lazer.override { nativeWayland = true; })
    pkg-config
    protonup-qt
    qbittorrent-enhanced
    qemu
    sbctl
    screenkey
    virt-manager
    zsh-powerlevel10k
  ];

  programs.vesktop = {
    enable = true;
    vencord.useSystem = true;
  };

  programs.spotify-player.enable = true;

  programs.command-not-found.enable = false;
}
