{
  inputs,
  outputs,
  lib,
  pkgs,
  config,
  modulesPath,
  ...
}:
with lib;
{
  imports = [
    ../../programs/nix
    # ../../programs/gpg  # no gpg here
    ../../programs/ssh
  ];

  wsl = {
    enable = true;
    automountPath = "/mnt";
    defaultUser = "vinny";
    startMenuLaunchers = true;

    # Enable native Docker support
    # docker-native.enable = true;

    # Enable integration with Docker Desktop (needs to be installed)
    # docker-desktop.enable = true;
  };

  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernel.sysctl."vm.overcommit_memory" = "1";

  documentation = {
    nixos.enable = true;
    man.enable = true;
    info.enable = true;
    doc.enable = true;
    dev.enable = true;
  };

  # services.xserver.videoDrivers = [ "nvidia" ];
  # hardware.graphics.enable = true;

  security.polkit.enable = true;

  users.users.vinny = {
    isNormalUser = true;
    initialPassword = "passwordington";
    extraGroups = [ "wheel" ];
    shell = pkgs.zsh;
  };
  programs.zsh = {
    enable = true;
    enableCompletion = false;
  };
  networking.hostName = "vindows"; # Define your hostname.

  services.github-nix-ci = {
    age.secretsDir = ../../secrets;
    runnerSettings = {
      extraPackages = with pkgs; [
        openssl # needed for nicknovitski/nix-develop
      ];
    };
    orgRunners = {
      "mxves".num = 2;
    };
  };

  environment.systemPackages = [
    pkgs.ragenix
  ];

  nixpkgs.hostPlatform = "x86_64-linux";
  system.stateVersion = "24.05";
}
