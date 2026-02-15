{
  config,
  lib,
  pkgs,
  inputs,
  outputs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.mine.nix;
in
{

  options.mine.nix = {
    enable = mkEnableOption "Enable nix configuration";
  };

  config = mkIf cfg.enable {
    nix = {
      package = pkgs.nixVersions.latest;
      settings = {
        experimental-features = [
          "nix-command"
          "flakes"
        ];
        auto-optimise-store = true;
        substituters = [
          "https://cache.nixos.org/"
          "https://nix-community.cachix.org/"
          "https://cache.nixos-cuda.org/"
          "https://hyprland.cachix.org/"
        ];
        trusted-users = [
          "root"
          "vinny"
        ];
        trusted-public-keys = [
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
          "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
          "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
        ];
      };
      gc = {
        automatic = true;
        options = "--delete-older-than 3d";
      };
      # package = pkgs.nixVersions.git;
      registry = (inputs.nixpkgs.lib.mapAttrs (_: flake: { inherit flake; })) (
        (inputs.nixpkgs.lib.filterAttrs (_: inputs.nixpkgs.lib.isType "flake")) inputs
      );
    };
    nixpkgs = {
      overlays = builtins.attrValues outputs.overlays;
      config = {
        allowUnfree = true;
        cudaSupport = true;
      };
    };

  };
}
