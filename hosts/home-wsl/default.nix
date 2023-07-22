{ nixpkgs, home-manager, overlays, ... }:

nixpkgs.lib.nixosSystem {
    modules = [
        { nixpkgs.hostPlatform = "x86_64-linux"; }
	{ nixpkgs.overlays = overlays; }
	./configuration.nix
        home-manager.nixosModules.home-manager {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.vinny = import ./home.nix;
        }
    ];
}
