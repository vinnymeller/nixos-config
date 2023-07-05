{ config, pkgs, users, ... }: {
  imports = [
    # ../../modules/xmonad
    # ../../modules/plasma
    ../../modules/qtile # ALSO need to make sure config is copied from home manager
  ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.gc.automatic = true;
  nix.settings.auto-optimise-store = true;
  nix.gc.options = "--delete-older-than 14d";

  security.polkit.enable = true;

  nixpkgs.config.permittedInsecurePackages = [
    "electron-12.2.3"
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # add ntfs support
  boot.supportedFilesystems = [ "ntfs" ];

  # use the newest kernel
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernelParams = [ "amd_iommu=on" ];
  boot.blacklistedKernelModules = [ "nvidia" "nouveau" ];
  boot.kernelModules = [
    "kvm-amd"
    "vfio_virqfd" "vfio_pci" "vfio_iommu_type1" "vfio" # gpu passthrough-related modules
  ];
  boot.extraModprobeConfig = ''
    options vfio-pci ids=10de:13c0,10de:0fbb
    options btusb enable_autosuspend=n
  '';


  nixpkgs.config.allowUnfree = true;
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.opengl.enable = true;

  # new xbox controllers
  hardware.xpadneo.enable = true;

  fonts.fontconfig.antialias = true;
  fonts.fontconfig.hinting.enable = true;

  networking.hostName = "vinnix"; # Define your hostname.
  networking.networkmanager.enable = true;  # Easiest to use and most distros use this by default.

  # bluetooth
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  # Set your time zone.
  time.timeZone = "America/Chicago";

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    useXkbConfig = true; # use xkbOptions in tty.
  };


  # Configure keymap in X11
  services.xserver.layout = "us";

  # Enable sound.
  sound.enable = true;
  hardware.pulseaudio.enable = true;

  services.pcscd.enable = true;
  services.spotifyd.enable = true;

  users.users.vinny = {
    isNormalUser = true;
    initialPassword = "passwordington";
    extraGroups = [ "wheel" "libvirtd" "kvm" "qemu-libvirtd" ];
    shell = pkgs.zsh;

  };

  environment.systemPackages = with pkgs; [
    vim
    zsh
    wget
    firefox
    # linuxPackages_latest.perf  # TODO: readd this when its working
    looking-glass-client
    openvpn
    podman-compose
    spice
    xclip
    scrot
    zoom-us
  ];

  systemd.tmpfiles.rules = [
    "f /dev/shm/looking-glass 0660 vinny kvm -" # looking-glass shmem
  ];

  virtualisation.libvirtd.enable = true;
  virtualisation.libvirtd.qemu.ovmf.enable = true;

  virtualisation.podman.enable = true;

  system.stateVersion = "22.11"; # read documentation on configuration.nix before possibly changing this

  programs.steam.enable = true;
  programs.zsh.enable = true;

  services.picom = {
    enable = true;
    backend = "glx";
    fade = true;
    fadeDelta = 5;
    opacityRules = [
                    "100:QTILE_INTERNAL:32c"
                  ];
    shadow = true;
    shadowOpacity = 0.5;
  };

  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    alsa-lib
    at-spi2-atk
    at-spi2-core
    atk
    cairo
    cups
    curl
    dbus
    expat
    fontconfig
    freetype
    fuse3
    gdk-pixbuf
    glib
    gtk3
    icu
    libGL
    libappindicator-gtk3
    libdrm
    libnotify
    libpulseaudio
    libusb1
    libuuid
    libxkbcommon
    mesa
    nspr
    nss
    openssl
    pango
    pipewire
    stdenv.cc.cc
    systemd
    xorg.libX11
    xorg.libXScrnSaver
    xorg.libXcomposite
    xorg.libXcursor
    xorg.libXdamage
    xorg.libXext
    xorg.libXfixes
    xorg.libXi
    xorg.libXrandr
    xorg.libXrender
    xorg.libXtst
    xorg.libxcb
    xorg.libxkbfile
    xorg.libxshmfence
    zlib
  ];
}
