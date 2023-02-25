{
  description = "Vinny's NixOS Configuration";

  inputs = {
    # nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs.url = "nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, nixpkgs, home-manager, ... }:
  let
    # system = "x86_64-linux";
    # pkgs = import nixpkgs { inherit system; };
  in {
    nixosConfigurations = {
        vinnix = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          pkgs = import nixpkgs { system = system; };
          # system = "x86_64-linux";
          modules = [
            ./system/configuration.nix
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.vinny = import ./users/vinny/home.nix;
            }
          ];
        };

    };
    homeConfigurations.vinny = home-manager.lib.homeManagerConfiguration {
            inherit pkgs;
            modules = [
                ./users/vinny/home.nix
            ];
        };
    packages.${system}.vinny = self.homeConfigurations.vinny.activationPackage;
    packages."x86_64-darwin".vmeller = self.homeConfigurations.vinny.activationPackage;
  };
}
