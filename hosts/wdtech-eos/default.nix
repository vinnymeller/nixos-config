{ nixpkgs, home-manager, overlays, ... }:
home-manager.lib.homeManagerConfiguration {
    pkgs = nixpkgs.legacyPackages.x86_64-linux;
    modules = [
        { nixpkgs.overlays = overlays; }
        ./home.nix
    ];
}
