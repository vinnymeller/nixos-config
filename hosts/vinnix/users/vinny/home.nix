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
    inputs.noctalia.homeModules.default
  ];
  programs.noctalia-shell = {
    enable = true;
    systemd.enable = true;
    settings = {
      # configure noctalia here
      bar = {
        density = "compact";
        position = "right";
        showCapsule = true;
        widgets = {
          left = [
            {
              id = "ControlCenter";
              useDistroLogo = true;
            }
            {
              id = "WiFi";
            }
            {
              id = "Bluetooth";
            }
          ];
          center = [
            {
              hideUnoccupied = false;
              id = "Workspace";
              labelMode = "none";
            }
          ];
          right = [
            {
              formatHorizontal = "HH:mm";
              formatVertical = "HH mm";
              id = "Clock";
              useMonospacedFont = true;
              usePrimaryColor = true;
            }
          ];
        };
      };
      colorSchemes.predefinedScheme = "Gruvbox";
      general = {
        avatarImage = ../../../../files/avatar.png;
        radiusRatio = 0.2;
      };
      location = {
        monthBeforeDay = true;
        name = "Chicago, United States";
        useFahrenheit = true;
      };
    };
  };

  home.file.".cache/noctalia/wallpapers.json" = {
    text = builtins.toJSON {
      defaultWallpaper = ../../../../files/avatar-wallpaper.png;
    };
  };

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
      discord-canary
      gocryptfs
      htop
      libreoffice
      libvirt
      lxsession
      man-pages # linux man pages, goes with tlpi
      neofetch
      nerd-fonts._0xproto
      nix-init
      obs-studio
      (master-pkgs.osu-lazer.override { nativeWayland = true; })
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
    ]
    ++ builtins.attrValues cust_pkgs;

  programs.vesktop = {
    enable = true;
    vencord.useSystem = true;
  };
  programs.spotify-player.enable = true;

  programs.command-not-found.enable = false;

  home.file.".config/nixpkgs".source = ../../../../dotfiles/nixpkgs;
}
