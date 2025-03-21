{
  inputs,
  outputs,
  config,
  pkgs,
  users,
  ...
}:
{
  imports = [
    ../../programs/nix
    # ../../programs/qtile # ALSO need to make sure config is copied from home manager
    ../../programs/gpg
    ../../programs/ssh
    ../../modules/nixos
  ];

  uses.selfhost = true;

  nixpkgs = {
    overlays = builtins.attrValues outputs.overlays;
    config = {
      permittedInsecurePackages = [ "electron-25.9.0" ];
      allowBroken = true; # should probably set to false every once in a while to see if broken packages are fixed
      allowUnfree = true;
    };
  };

  boot.initrd.luks.devices = {
    crypted = {
      device = "/dev/disk/by-uuid/671efa4e-c795-4044-9b3a-24c1242c5394";
      preLVM = true;
    };
  };

  boot = {
    supportedFilesystems = [ "ntfs" ];
    kernelPackages = pkgs.linuxPackages_latest; # use newest kernel
    kernelParams = [
      "amd_iommu=soft"
      "processor.max_cstate=4"
      "idle=nomwait"
    ];
    blacklistedKernelModules = [
      #"nvidia"
      #"nouveau"
    ];
    kernelModules = [
      "kvm-amd"
      "vfio_virqfd"
      "vfio_pci"
      "vfio_iommu_type1"
      "vfio"
    ];
    extraModprobeConfig = ''
      options btusb enable_autosuspend=n
    '';
    loader = {
      systemd-boot = {
        enable = true;
        # windows = {
        #   "11-windows-pro" = {
        #     title = "Windows 11 Pro";
        #     efiDeviceHandle = "HD1b";
        #   };
        # };
      };
      efi = {
        canTouchEfiVariables = true;
      };
    };
    kernel = {
      sysctl = {
        "net.ipv4.ip_forward" = 1;
        "vm.overcommit_memory" = 1;
      };
    };
  };

  security = {
    polkit = {
      enable = true;
    };
    pam = {
      loginLimits = [
        {
          domain = "*";
          type = "soft";
          item = "nofile";
          value = 100000;
        }
      ];
    };
  };

  hardware = {
    bluetooth = {
      enable = true;
      powerOnBoot = true;
    };
    graphics = {
      enable = true;
      #extraPackages = [ pkgs.nvidia-vaapi-driver ];
    };
    # pulseaudio.enable = true;
    # xpadneo.enable = true;
    opentabletdriver.enable = true; # OSU TABLET HERE WE GOOOOOOOO
  };

  mine.dm.qtile.enable = true;

  services = {
    blueman.enable = true;
    pcscd.enable = true;
    # spotifyd.enable = true;
    pipewire = {
      enable = true;
      pulse.enable = true;
      alsa.enable = true;
      jack.enable = true;
    };
    mullvad-vpn.enable = true;
    yubikey-agent.enable = true;
    devmon.enable = true;
    gnome.gnome-keyring.enable = true;
    gvfs.enable = true;
    udisks2.enable = true;
  };

  fonts = {
    fontconfig = {
      antialias = true;
      hinting.enable = true;
    };
  };

  documentation = {
    nixos.enable = true;
    man.enable = true;
    info.enable = true;
    doc.enable = true;
    dev.enable = true;
  };

  networking.hostName = "vinnix"; # Define your hostname.
  networking.networkmanager.enable = true; # Easiest to use and most distros use this by default.

  # Set your time zone.
  time.timeZone = "America/Detroit";

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    useXkbConfig = true; # use xkbOptions in tty.
  };

  users.users = {
    vinny = {
      isNormalUser = true;
      initialPassword = "passwordington";
      extraGroups = [
        "wheel"
        "libvirtd"
        "kvm"
        "qemu-libvirtd"
      ];
      shell = pkgs.zsh;
    };
  };

  environment.pathsToLink = [ "/share/zsh" ];
  environment.systemPackages = with pkgs; [
    # linuxPackages_latest.perf  # TODO: readd this when its working
    # openvpn
    ragenix
    firefox
    gnupg
    killall
    pkgs.stable-pkgs.looking-glass-client
    man-pages
    man-pages-posix
    podman-compose
    scrot
    spice
    vim
    wget
    xclip
    zsh
  ];

  systemd.tmpfiles.rules = [
    "f /dev/shm/looking-glass 0660 vinny kvm -" # looking-glass shmem
  ];

  virtualisation.libvirtd.enable = true;
  virtualisation.libvirtd.qemu.ovmf.enable = true;

  virtualisation.podman = {
    enable = true;
    dockerSocket.enable = true;
    autoPrune.enable = true;
    dockerCompat = true;
  };

  # this replaces virtualisation.podman.enableNvidia
  # this replaces  virtualisation.containers.cdi.dynamic.nvidia.enable lol
  #hardware.nvidia-container-toolkit.enable = true;
  hardware.nvidia.open = true;

  system.stateVersion = "22.11"; # read documentation on configuration.nix before possibly changing this

  programs.steam.enable = true;
  programs.zsh = {
    enable = true;
    enableCompletion = false;
  };

  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
    pinentryPackage = pkgs.pinentry-gnome3;
  };
  hardware.gpgSmartcards.enable = true; # for yubikey

  # Tag each generation with Git hash
  # system.configurationRevision =
  #   if (inputs.self ? rev) then
  #     inputs.self.shortRev
  #   else
  #     throw "Refusing to build from a dirty Git tree!";
  # system.nixos.label = "GitRev.${config.system.configurationRevision}.Rel.${config.system.nixos.release}";

  programs.command-not-found.enable = false;

  programs.nm-applet.enable = true;

  programs.nix-ld.enable = true;
}
