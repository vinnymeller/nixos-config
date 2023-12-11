{ inputs, ... }: {
  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
      substituters = [
      	"https://nix-community.cachix.org"
	"https://cache.nixos.org"
      ];
      trusted-public-keys = [
      	"nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
      trusted-users = [ "vinny" "root" ];
      require-sigs = false;
    };
    gc = {
      automatic = true;
      options = "--delete-older-than 14d";
    };
    registry = {
      nixpkgs = {
        flake = inputs.nixpkgs;
      };
    };
  };

  nixpkgs = {
    config = {
      allowUnfree = true;
    };
  };
}