{ master-pkgs-overlay, nixpkgs, neovim-nightly-overlay, home-manager, ... }:

nixpkgs.lib.nixosSystem {
    modules = [
        { nixpkgs.overlays = [ master-pkgs-overlay neovim-nightly-overlay.overlay ]; }
        ./system.nix
        ./hardware.nix
        home-manager.nixosModules.home-manager {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.vinny = import ./users/vinny/home.nix;
        }
    ];
}
