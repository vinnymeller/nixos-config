{ inputs, outputs, ... }:
inputs.home-manager.lib.homeManagerConfiguration {
<<<<<<< HEAD
  pkgs = inputs.nixpkgs.legacyPackages.aarch64-darwin;
  extraSpecialArgs = { inherit inputs outputs; };
  modules = [
    ./home.nix
  ];
=======
    pkgs = import inputs.nixpkgs {
        system = "aarch64-darwin";
        config = {
            allowUnfree = true;
        };
    };
    extraSpecialArgs = { inherit inputs outputs; };
    modules = [
        ./home.nix
    ];
>>>>>>> 8e08d34 (add laptop changes)
}
