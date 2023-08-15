{ inputs, outputs, ... }:
inputs.home-manager.lib.homeManagerConfiguration {
    pkgs = inputs.nixpkgs.legacyPackages.aarch64-darwin;
    extraSpecialArgs = { inherit inputs outputs; };
    modules = [
        ./home.nix
    ];
}
