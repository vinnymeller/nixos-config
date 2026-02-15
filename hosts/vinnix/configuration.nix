{
  inputs,
  lib,
  outputs,
  config,
  pkgs,
  ...
}:
{
  imports = [
    ../../modules/nixos
  ];

  profile.selfhost = true;

  nixpkgs = {
    overlays = builtins.attrValues outputs.overlays;
    config = {
      permittedInsecurePackages = [ "electron-25.9.0" ];
      allowBroken = true; # should probably set to false every once in a while to see if broken packages are fixed
      allowUnfree = true;
    };
  };

  age.secrets.vinnix-wpa-initrd = {
    file = ../../secrets/vinnix/wpa_supplicant.conf.age;
    path = "/etc/secrets/initrd/wpa_supplicant.conf";
    symlink = false;
  };
  age.secrets.vinnix-tailscale-authkey = {
    file = ../../secrets/vinnix/tailscale-authkey.age;
    mode = "0400";
  };

  boot.initrd =
    let
      deviceUuid = "671efa4e-c795-4044-9b3a-24c1242c5394";
      device = "/dev/disk/by-uuid/${deviceUuid}";
      interface = "wlp8s0";
    in
    {
      kernelModules = [
        "rtw89_8922ae"
        "ccm"
        "ctr"
        "cmac" # for IGTK / management frame protection
      ];

      network = {
        enable = true;
        ssh = {
          enable = true;
          port = 2222;
          authorizedKeys = config.users.users.vinny.openssh.authorizedKeys.keys;
          hostKeys = [
            "/etc/secrets/initrd/ssh_host_rsa_key"
            "/etc/secrets/initrd/ssh_host_ed25519_key"
          ];
        };
      };

      luks.devices.crypted = {
        device = device;
        preLVM = true;
      };

      systemd = {
        enable = true;
        packages = [ pkgs.wpa_supplicant ];
        initrdBin = [ pkgs.wpa_supplicant ];
        targets.initrd.wants = [ "wpa_supplicant@${interface}.service" ];
        services = {
          "wpa_supplicant@" = {
            unitConfig.DefaultDependencies = false;
            after = lib.mkForce [ "sys-subsystem-net-devices-%i.device" ];
            requires = lib.mkForce [ "sys-subsystem-net-devices-%i.device" ];
          };
          sshd = {
            after = lib.mkForce [ "network.target" ];
            wants = lib.mkForce [ ];
            requires = lib.mkForce [ ];
          };
        };
        network = {
          enable = true;
          networks."10-wlan" = {
            matchConfig.Name = interface;
            networkConfig.DHCP = "no";
            address = [ "172.16.100.201/24" ];
            gateway = [ "172.16.100.1" ];
            dns = [ "172.16.100.1" ];
          };
        };
      };

      # need to rebuild twice
      secrets."/etc/wpa_supplicant/wpa_supplicant-${interface}.conf" =
        config.age.secrets.vinnix-wpa-initrd.path;
    };

  boot = {
    supportedFilesystems = [ "ntfs" ];
    kernelPackages = pkgs.linuxPackages_latest; # use newest kernel
    kernelParams = [
      "ip=dhcp"
      "amd_iommu=soft"
      "processor.max_cstate=4"
      "idle=nomwait"
    ];
    blacklistedKernelModules = [
      #"nvidia"
      "nouveau"
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
      enable32Bit = true;
      extraPackages = with pkgs; [
        mesa
        libva-vdpau-driver
        nvidia-vaapi-driver
      ];
    };
    # pulseaudio.enable = true;
    # xpadneo.enable = true;
    opentabletdriver.enable = true; # OSU TABLET HERE WE GOOOOOOOO
  };

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
    yubikey-agent.enable = true;
    devmon.enable = true;
    gnome.gnome-keyring.enable = true;
    gvfs.enable = true;
    udisks2.enable = true;
    resolved = {
      enable = true;
      settings = {
        Resolve = { };
      };
    };
    tailscale = {
      enable = true;
      authKeyFile = config.age.secrets.vinnix-tailscale-authkey.path;
    };
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

  users.users = {
    vinny = {
      isNormalUser = true;
      initialPassword = "passwordington";
      extraGroups = [
        "wheel"
        "libvirtd"
        "kvm"
        "qemu-libvirtd"
        "docker"
      ];
      shell = pkgs.zsh;
      openssh = {
        authorizedKeys = {
          keys = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIZZ4L3vUmq827YJYRgupHjefxXX87OPPRpr+K0JB8NG"
            "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDkkYpg0w3r7I7NgQn3tTUbMZ3BSYeEQ1jA5zcQ8f6u9POWl///j5uIkJGUJ7ULNQJjAGxGiwXZ3pTqWm6kbErlP+SjzuNAznXmhbu/4xVb7ui0OCHq5riK62O3zLKMiK7ZWqeSUwc+iJHWNCmBaS0TXjqwj++1fU1o3xBZX2shNQQD6Ke6VDqJ1bEbE3d8yLfFiKjfZXTJ6/YKxyVO15hCn5urEIG6efEG+t0w7fwuHyA1dFfuUXSw9VuHcMxPNeYqVJa29ITz+CXdDvcXGXb4qOz60nvUHVZpBl/WjyhB3N+UXopAvd0v/ZB9Y0wqPNB8VX25+LURVpcPqeOOCEiDHrQmX6DCgVp07Y52wpgcBf5iiEk586BaeQBuA0Tn25m31YX9j10teLYp2pwJ7a1/DXUJtkO1IKLWGs0Hs38VgB5jmXjlsSXsnMkgpt8is7Uacm11BTmnJrPyF+sqWfT7WPuG5FsQ6Bk/rgnTP7LOs+kdJVxTMIyOCEskVW7u0eykofgs1zBAe9UyUp5UeQlCos++o3W0MO4xmBFhkkss7klRCHLJK0M047BFUX4WbnfqUDpXjON3kUl0LQwtm5QeFoSWH+tu3Y4o1B0+lIq47Up2Q2X4BDdfGS0dvmgGMXfXUcz467pYqLMzOfJpI/zZC7nAPlzRtA2JJvdK7fAtow=="
          ];
        };
      };
    };
  };

  environment.pathsToLink = [ "/share/zsh" ];
  environment.systemPackages = with pkgs; [
    # linuxPackages_latest.perf  # TODO: readd this when its working
    # openvpn
    ragenix
    # firefox
    gnupg
    killall
    man-pages
    man-pages-posix
    spice
    vim
    wget
    wl-clipboard
    zsh
    libva-utils
    nvtopPackages.full
  ];

  virtualisation.libvirtd.enable = true;

  # this replaces virtualisation.podman.enableNvidia
  # this replaces  virtualisation.containers.cdi.dynamic.nvidia.enable lol
  #hardware.nvidia-container-toolkit.enable = true;

  system.stateVersion = "25.05"; # read documentation on configuration.nix before possibly changing this

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

  programs.hyprland = {
    package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
    portalPackage =
      inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;

    enable = true;
    withUWSM = true;
  };
  security.pam.services.hyprlock = { };
  services.xserver.videoDrivers = [
    "nvidia"
  ];
  hardware.nvidia = {
    package = config.boot.kernelPackages.nvidiaPackages.beta;
    modesetting.enable = true;
    open = true;
    nvidiaSettings = true;
  };
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd hyprland";
        user = "vinny";
      };
    };
  };

  services.udev.extraRules = ''
    # 3090
    KERNEL=="card*", SUBSYSTEM=="drm", SUBSYSTEMS=="pci", KERNELS=="0000:01:00.0", SYMLINK+="dri/nvidia"
  '';

  security.pam.services = {
    greetd.enableGnomeKeyring = true;
    login.enableGnomeKeyring = true;
  };

}
