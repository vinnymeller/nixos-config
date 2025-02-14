{
  inputs,
  pkgs,
  outputs,
  ...
}:
{
  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      auto-optimise-store = true;
      substituters = [
        "https://nix-community.cachix.org"
        "https://cache.nixos.org"
      ];
      trusted-users = [ "root" "vinny" ];
      trusted-public-keys = [ "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=" ];
    };
    gc = {
      automatic = true;
      options = "--delete-older-than 14d";
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
    };
  };
}
