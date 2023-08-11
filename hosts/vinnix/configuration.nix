{ inputs, outputs, config, pkgs, users, ... }: {

  imports = [
    ../../modules/qtile # ALSO need to make sure config is copied from home manager
  ];

  nix = {
      settings = {
          experimental-features = [ "nix-command" "flakes" ];
          auto-optimise-store = true;
      };
      gc = {
          automatic = true;
          options = "--delete-older-than 14d";
      };
  };

  nixpkgs = {
    overlays = builtins.attrValues outputs.overlays;
    config = {
      permittedInsecurePackages = [ "electron-12.2.3" ];
      allowUnfree = true;
    };
  };

  boot = {
      supportedFilesystems = [ "ntfs" ];
      kernelPackages = pkgs.linuxPackages_latest;  # use newest kernel
      kernelParams = [ "amd_iommu=on" ];
      blacklistedKernelModules = [ "nvidia" "nouveau" ];
      kernelModules = [ "kvm-amd" "vfio_virqfd" "vfio_pci" "vfio_iommu_type1" "vfio" ];
      extraModprobeConfig = ''
        options vfio-pci ids=10de:13c0,10de:0fbb
        options btusb enable_autosuspend=n
      '';
      loader = {
          systemd-boot = {
              enable = true;
          };
          efi = {
              canTouchEfiVariables = true;
          };
      };
  };

  security = {
    polkit = {
      enable = true;
    };
  };

  hardware = {
      bluetooth.enable = true;
      opengl.enable = true;
      pulseaudio.enable = true;
      xpadneo.enable = true;
  };

  services = {
      blueman.enable = true;
      pcscd.enable = true;
        spotifyd.enable = true;
        mullvad-vpn.enable = true;

  };

  fonts = {
      fontconfig = {
          antialias = true;
          hinting.enable = true;
      };
  };



  networking.hostName = "vinnix"; # Define your hostname.
  networking.networkmanager.enable = true;  # Easiest to use and most distros use this by default.


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

  # Enable sound.
  sound.enable = true;


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
    man-pages
    man-pages-posix
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
