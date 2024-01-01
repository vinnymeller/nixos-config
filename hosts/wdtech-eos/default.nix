{ inputs, outputs, ... }:
inputs.home-manager.lib.homeManagerConfiguration {
  pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
  extraSpecialArgs = { inherit inputs outputs; };
  modules = [ ./home.nix ];
}
