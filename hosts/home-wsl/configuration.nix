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
#let
#  nixos-wsl = import ./nixos-wsl;
#in
{
  imports = [
#    "${modulesPath}/profiles/minimal.nix"

#    nixos-wsl.nixosModules.wsl

    ../../programs/nix
    ../../programs/gpg
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

  nixpkgs.hostPlatform = "x86_64-linux";
  nixpkgs.overlays = builtins.attrValues outputs.overlays;
  nixpkgs.config.allowBroken = true;
  # Enable nix flakes
  nix.package = pkgs.nixVersions.stable;
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  nix.gc.automatic = true;
  nix.settings.auto-optimise-store = true;
  nix.gc.options = "--delete-older-than 14d";

  boot.kernelPackages = pkgs.linuxPackages_latest;

  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.graphics.enable = true;

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

  environment.systemPackages = with pkgs; [
    git
    vim
    neovim
  ];
  nixpkgs.config.allowUnfree = true;
  system.stateVersion = "24.05";
}
