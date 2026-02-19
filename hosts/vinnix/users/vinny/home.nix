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
    inputs.voxtype.homeManagerModules.default
  ];
  # Let home-manager manage itself
  profile.vinny.enable = true;
  profile.vinny.hyprland = true;

  home.username = "vinny";
  home.homeDirectory = "/home/vinny";
  home.stateVersion = "25.11";

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
      zed-editor
    ]
    ++ builtins.attrValues cust_pkgs;

  programs.vesktop = {
    enable = true;
    vencord.useSystem = true;
  };
  programs.spotify-player.enable = true;

  programs.voxtype = {
    enable = true;
    package = inputs.voxtype.packages.${pkgs.stdenv.hostPlatform.system}.vulkan;
    model.name = "large-v3";
    service.enable = true;
    settings = {
      audio = {
        device = "default";
        sample_rate = 16000;
        max_duration_secs = 60;
      };
      hotkey.enabled = false;
      whisper.language = "en";
      output.mode = "type";
      output.auto_submit = true;
      output.notification.on_recording_start = true;
      output.notification.on_recording_stop = true;
      text.replacements = {
        "Knicks" = "Nix";
      };
    };
  };
  programs.command-not-found.enable = false;
}
