{ inputs, outputs, ... }:
inputs.home-manager.lib.homeManagerConfiguration {
  pkgs = import inputs.nixpkgs {
    system = "aarch64-darwin";
    config = {
      allowUnfree = true;
    };
  };
  extraSpecialArgs = {
    inherit inputs outputs;
  };
  modules = [ ./home.nix ];
}
