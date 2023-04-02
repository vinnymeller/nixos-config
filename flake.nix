{
  description = "Vinny's NixOS Configuration";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, nixpkgs, home-manager, ... }: {
    defaultPackage.x86_64-linux = home-manager.defaultPackage.x86_64-linux;
    defaultPackage.x86_64-darwin = home-manager.defaultPackage.x86_64-darwin;

    nixosConfigurations = {
        vinnix = import ./hosts/vinnix { inherit nixpkgs home-manager; };
    };
    homeConfigurations = {
        vinny = import ./hosts/wdtech-eos { inherit nixpkgs home-manager; };
    };
  };
}
