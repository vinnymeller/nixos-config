{ pkgs, ... }:
{
  imports = [
    ../../../../modules/home-manager
  ];
  home.stateVersion = "25.11";

  home.packages = with pkgs; [
    feh
    gcc
    discord-canary
    gocryptfs
    htop
    jellyfin-desktop
    libvirt
    lxsession
    man-pages # linux man pages, goes with tlpi
    fastfetch
    nerd-fonts._0xproto
    nix-init
    obs-studio
    (master-pkgs.osu-lazer.override { nativeWayland = true; })
    pavucontrol
    pkg-config
    protonup-qt
    qbittorrent-enhanced
    qemu
    sbctl
    screenkey
    virt-manager
    yubioath-flutter
    yubikey-manager
    zsh-powerlevel10k
  ];

  programs.vesktop = {
    enable = true;
    vencord.useSystem = true;
  };

  xdg.desktopEntries = {
    grimmory = {
      name = "Grimmory";
      exec = "${pkgs.google-chrome}/bin/google-chrome-stable --app=https://grimmory.vinnix.net";
      icon = "booklore";
      type = "Application";
    };
    paperless = {
      name = "Paperless-ngx";
      exec = "${pkgs.google-chrome}/bin/google-chrome-stable --app=https://paperless.vinnix.net";
      icon = "paperless-ngx";
      type = "Application";
    };
  };

  programs.spotify-player.enable = true;

  programs.command-not-found.enable = false;
}
