{
  description = "Vinny's NixOS Configuration";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, nixpkgs, home-manager, ... }:
   let
     system = "x86_64-linux";
     pkgs = import nixpkgs { inherit system; };
   in {
    nixosConfigurations = {
        vinnix = nixpkgs.lib.nixosSystem {
          modules = [
            ./hardware/vinnix.nix
            ./system/vinnix.nix
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.vinny = import ./users/vinny/home.nix;
            }
          ];
        };
	wdtech = nixpkgs.lib.nixosSystem {
	  modules = [
	    ./hardware/wdtech.nix
 	    ./system/wdtech.nix
	    home-manager.nixosModules.home-manager {
	      home-manager.useGlobalPkgs = true;
	      home-manager.useUserPackages = true;
	      home-manager.users.vinny = import ./users/vinny/home.nix;
	    }
	  ];
	};
    };
  };
}
