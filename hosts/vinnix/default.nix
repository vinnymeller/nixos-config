{ nixpkgs, home-manager, lanzaboote, overlays, ... }:

nixpkgs.lib.nixosSystem {
    modules = [
        lanzaboote.nixosModules.lanzaboote

        ({ pkgs, lib, ... }: {
             environment.systemPackages = [
                pkgs.sbctl
             ];

             boot.loader.systemd-boot.enable = lib.mkForce false;

             boot.lanzaboote = {
                 enable = true;
                 pkiBundle = "/etc/secureboot";
             };
         })

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
