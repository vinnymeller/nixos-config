{
  options =
    { lib, ... }:
    {
      experimentalFeatures = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [
          "nix-command"
          "flakes"
        ];
      };
      autoOptimiseStore = lib.mkOption {
        type = lib.types.bool;
        default = true;
      };
      substituters = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [
          "https://cache.nixos.org/"
          "https://nix-community.cachix.org/"
          "https://cache.nixos-cuda.org/"
          "https://hyprland.cachix.org/"
          "https://cache.numtide.com"
        ];
      };
      trustedPublicKeys = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
          "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
          "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
          "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
        ];
      };
      gcDeleteOlderThan = lib.mkOption {
        type = lib.types.str;
        default = "3d";
      };
    };

  nixos =
    {
      cfg,
      config,
      lib,
      pkgs,
      inputs,
      ...
    }:
    {
      nix = {
        package = lib.mkForce pkgs.lixPackageSets.latest.lix;
        settings = {
          experimental-features = cfg.experimentalFeatures;
          auto-optimise-store = lib.mkDefault cfg.autoOptimiseStore;
          substituters = cfg.substituters;
          trusted-users = cfg.users;
          trusted-public-keys = cfg.trustedPublicKeys;
        };
        gc = {
          automatic = lib.mkDefault true;
          options = lib.mkDefault "--delete-older-than ${cfg.gcDeleteOlderThan}";
        };
        registry = (
          (inputs.nixpkgs.lib.mapAttrs (_: flake: { inherit flake; })) (
            (inputs.nixpkgs.lib.filterAttrs (_: inputs.nixpkgs.lib.isType "flake")) inputs
          )
        );
      };
    };

  home =
    {
      cfg,
      lib,
      pkgs,
      ...
    }:
    {
      nix = {
        package = lib.mkForce pkgs.lixPackageSets.latest.lix;
        settings = {
          experimental-features = cfg.experimentalFeatures;
          require-sigs = lib.mkDefault true;
          auto-optimise-store = lib.mkDefault cfg.autoOptimiseStore;
          trusted-users = cfg.users;
        };
      };
      home.packages = with pkgs; [
        check-duplicate-flake-deps
      ];
    };
}
