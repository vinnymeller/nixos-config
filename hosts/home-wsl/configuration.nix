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
    ../../modules/nixos
  ];

  features.defaults.users = [ "vinny" ];
  features.git.enable = true;
  features.nix.enable = true;
  features.ssh.enable = true;
  features.tmux.enable = true;
  features.wsl.enable = true;
  features.zsh.enable = true;

  mine.networking.enable = false;

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
    initialHashedPassword = "$6$GUm.78.XWDWW/7CE$TVA9j1bmmKEMiQ2289etaddvpaYpVUUWagW7A.TM6K13RThGq.E3f7MgPh.bBurysjJDDkceZDz7.CEhXUsY6.";
    extraGroups = [
      "wheel"
      "docker"
    ];
  };
  networking.hostName = "vindows"; # Define your hostname.

  profile.selfhost = true;

  environment.systemPackages = [
    pkgs.ragenix
  ];
  environment.pathsToLink = [
    "/"
  ];

  nixpkgs.hostPlatform = "x86_64-linux";
  system.stateVersion = "25.11";
}
