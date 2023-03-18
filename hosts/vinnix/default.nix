{ nixpkgs, home-manager, ... }:

nixpkgs.lib.nixosSystem {
    modules = [
        ./system.nix
        ./hardware.nix
        home-manager.nixosModules.home-manager {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.vinny = import ./users/vinny/home.nix;
        }
    ];
}
