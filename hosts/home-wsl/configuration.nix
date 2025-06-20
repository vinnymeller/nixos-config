{
  inputs,
  outputs,
  lib,
  pkgs,
  config,
  modulesPath,
  ...
}:
{
  imports = [
    ../../programs/nix
    # ../../programs/gpg  # no gpg here
    ../../programs/ssh
    ../../modules/nixos
  ];

  wsl = {
    enable = true;
    wslConf.automount.root = "/mnt";
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

  virtualisation.docker.enable = true;
  security.polkit.enable = true;

  users.users.vinny = {
    isNormalUser = true;
    initialPassword = "passwordington";
    extraGroups = [
      "wheel"
      "docker"
    ];
    shell = pkgs.zsh;
  };
  programs.zsh = {
    enable = true;
    enableCompletion = false;
  };
  networking.hostName = "vindows"; # Define your hostname.

  uses.selfhost = true;

  environment.systemPackages = [
    pkgs.ragenix
  ];
  environment.pathsToLink = [
    "/"
  ];

  nixpkgs.hostPlatform = "x86_64-linux";
  system.stateVersion = "24.05";
}
