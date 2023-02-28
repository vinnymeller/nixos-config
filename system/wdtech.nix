{ config, pkgs, ... }:

{
  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "wdtech"; # Define your hostname.

  # Set your time zone.
  time.timeZone = "America/Chicago";


  # Enable the X11 windowing system.
  services.xserver.enable = true;
  services.xserver.displayManager.sddm.enable = true;
  services.xserver.desktopManager.plasma5.enable = true;
  services.xserver.autorun = true;


  sound.enable = true;
  hardware.pulseaudio.enable = true;

  # bluetooth 
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  users.users.vinny = {
    isNormalUser = true;
    initialPassword = "passwordington";
    extraGroups = [ "wheel" "libvirtd" ];
    shell = pkgs.zsh;

  };

  services.xserver.layout = "us";

  environment.systemPackages = with pkgs; [
    vim
    wget
    git
  ];

  system.stateVersion = "22.11";

}
