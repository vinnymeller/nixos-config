{
  inputs,
  lib,
  config,
  pkgs,
  ...
}:
{
  imports = [
    ../../modules/nixos
    inputs.claude-cowork-service.nixosModules.default
  ];

  profile.selfhost = true;

  features.defaults.users = [ "vinny" ];

  features.git.enable = true;
  features.gpg.enable = true;
  features.gpg.pinentryPackage = pkgs.pinentry-gnome3;
  features.gpg.smartcards = true;
  features.grimmory.enable = true;
  features.grimmory.secretFile = ../../secrets/vinnix/grimmory.age;
  features.hyprland.enable = true;
  features.immich.enable = true;
  features.immich.secretFile = ../../secrets/vinnix/immich.age;
  features.jellyfin.enable = true;
  features.kitty.enable = true;
  features.nix.enable = true;
  features.paperless.enable = true;
  features.paperless.secretFile = ../../secrets/vinnix/paperless.age;
  features.ssh.enable = true;
  features.tailscale.authKeyFile = ../../secrets/vinnix/tailscale-authkey.age;
  features.tailscale.enable = true;
  features.tmux.enable = true;
  features.vpn.airvpn.pskFile = ../../secrets/vinnix/airvpn-wg-psk.age;
  features.vpn.airvpn.secretFile = ../../secrets/vinnix/airvpn-wg-key.age;
  features.vpn.enable = true;
  features.vpn.mullvad.secretFile = ../../secrets/vinnix/mullvad-wg-key.age;
  features.vtt.enable = true;
  features.vtt.geminiKeyFile = ../../secrets/vtt/gemini.age;
  features.zk.enable = true;
  features.zsh.enable = true;

  environment.etc.crypttab.text = ''
    data UUID=a84a3eeb-8805-4299-9467-a8cd4912a059 /etc/luks-keys/data.key luks
  '';

  fileSystems."/data" = {
    device = "/dev/mapper/data";
    fsType = "btrfs";
    options = [
      "defaults"
      "noatime"
    ];
  };

  mine.services.restic = {
    enable = true;
    rcloneConfAge = ../../secrets/vinnix/rclone.conf.age;
    passwordFileAge = ../../secrets/vinnix/restic-password.age;
    providers = {
      backblaze.target = "backblaze:vinnix-restic";
      storj.target = "storj:restic";
    };
    onFailure = {
      enable = true;
      notifyUser = "vinny";
    };
  };
  mine.services.dockerCompose.tailscale = {
    tailnet = "coyote-fir";
    customDomain = "vinnix.net";
    cloudflareTokenFile = ../../secrets/vinnix/cloudflare-dns-token.age;
  };

  age.secrets.vinnix-wpa-initrd = {
    file = ../../secrets/vinnix/wpa_supplicant.conf.age;
    path = "/etc/secrets/initrd/wpa_supplicant.conf";
    symlink = false;
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
    tmp.cleanOnBoot = true;
    supportedFilesystems = [ "ntfs" ];
    kernelPackages = pkgs.linuxPackages_latest; # use newest kernel
    kernelParams = [
      "ip=dhcp"
      "amd_iommu=soft"
      "processor.max_cstate=4"
      "idle=nomwait"
      "rtw89_pci.disable_clkreq=Y"
      "rtw89_pci.disable_aspm_l1=Y"
      "rtw89_pci.disable_aspm_l1ss=Y"
      "rtw89_core.disable_ps_mode=Y"
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
    resolved = {
      enable = true;
      settings = {
        Resolve = { };
      };
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
      initialHashedPassword = "$6$GUm.78.XWDWW/7CE$TVA9j1bmmKEMiQ2289etaddvpaYpVUUWagW7A.TM6K13RThGq.E3f7MgPh.bBurysjJDDkceZDz7.CEhXUsY6.";
      uid = 1000;
      extraGroups = [
        "wheel"
        "libvirtd"
        "kvm"
        "qemu-libvirtd"
        "docker"
      ];
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
  users.groups.users.gid = 100;

  services.claude-cowork = {
    enable = true;
    extraPath = with pkgs; [
      nodejs
      python3
      claude-code
      coreutils-full
    ];
  };

  environment.systemPackages = with pkgs; [
    inputs.claude-desktop.packages.${pkgs.stdenv.hostPlatform.system}.default
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
    python3
    nodejs
    unzip
    smartmontools
    iw
    nftables
    tcpdump
    nvtopPackages.full
  ];

  # virtualisation.libvirtd.enable = true;

  system.stateVersion = "25.11"; # read documentation on configuration.nix before possibly changing this

  programs.steam.enable = true;

  # Tag each generation with Git hash
  # system.configurationRevision =
  #   if (inputs.self ? rev) then
  #     inputs.self.shortRev
  #   else
  #     throw "Refusing to build from a dirty Git tree!";
  # system.nixos.label = "GitRev.${config.system.configurationRevision}.Rel.${config.system.nixos.release}";

  programs.command-not-found.enable = false;

  programs.nix-ld.enable = true;

  services.xserver.videoDrivers = [
    "nvidia"
  ];
  hardware.nvidia = {
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    modesetting.enable = true;
    open = true;
    nvidiaSettings = true;
  };

  services.udev.extraRules = ''
    # 3090
    KERNEL=="card*", SUBSYSTEM=="drm", SUBSYSTEMS=="pci", KERNELS=="0000:01:00.0", SYMLINK+="dri/nvidia"
    # Disable WiFi power save for rtw89
    ACTION=="add", SUBSYSTEM=="net", KERNEL=="wl*", RUN+="${pkgs.iw}/bin/iw dev $name set power_save off"
    ACTION=="add", SUBSYSTEM=="net", KERNEL=="wl*", RUN+="${pkgs.iw}/bin/iw dev $name set bitrates he-mcs-5 2:4-11"
  '';

}
