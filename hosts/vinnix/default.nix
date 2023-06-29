{ nixpkgs, home-manager, overlays, ... }:

nixpkgs.lib.nixosSystem {
    modules = [
        { nixpkgs.overlays = overlays; }
        ./system.nix
        ./hardware.nix
        home-manager.nixosModules.home-manager {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.vinny = import ./users/vinny/home.nix;
        }
    ];
}
