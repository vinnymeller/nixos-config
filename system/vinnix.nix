{ config, pkgs, ... }:


{
  # imports =
    # [  Include the results of the hardware scan.
      # ./hardware-configuration.nix
    # ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  security.polkit.enable = true;


  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # use the newest kernel
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernelParams = [ "amd_iommu=on" ];
  boot.blacklistedKernelModules = [ "nvidia" "nouveau" ];
  boot.kernelModules = [
    "kvm-amd"
    "vfio_virqfd" "vfio_pci" "vfio_iommu_type1" "vfio" # gpu passthrough-related modules
  ];
  boot.extraModprobeConfig = "options vfio-pci ids=10de:13c0,10de:0fbb"; # vfio for old gtx 980

  nixpkgs.config.allowUnfree = true;
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.opengl.enable = true;


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

  # Setup X11
  services.xserver.enable = true;
  services.xserver.displayManager.sddm.enable = true;
  services.xserver.desktopManager.plasma5.enable = true;
  services.xserver.autoRepeatDelay = 200;
  services.xserver.autoRepeatInterval = 45;
  services.xserver.autorun = true;


  # Configure keymap in X11
  services.xserver.layout = "us";

  # Enable sound.
  sound.enable = true;
  hardware.pulseaudio.enable = true;

  services.pcscd.enable = true;

  users.users.vinny = {
    isNormalUser = true;
    initialPassword = "passwordington";
    extraGroups = [ "wheel" "libvirtd" ];
    shell = pkgs.zsh;

  };

  environment.systemPackages = with pkgs; [
    vim
    zsh
    wget
    firefox
    looking-glass-client
    spice
    zoom-us
  ];

  systemd.tmpfiles.rules = [
    "f /dev/shm/looking-glass 0660 vinny kvm -" # looking-glass shmem
  ];

  virtualisation.libvirtd.enable = true;
  virtualisation.libvirtd.qemu.ovmf.enable = true;

  system.stateVersion = "22.11"; # read documentation on configuration.nix before possibly changing this

}
