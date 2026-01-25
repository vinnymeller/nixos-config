{
  inputs,
  outputs,
  vlib,
  ...
}:
inputs.home-manager.lib.homeManagerConfiguration {
  pkgs = import inputs.nixpkgs {
    system = "aarch64-darwin";
    config = {
      allowUnfree = true;
    };
  };
  extraSpecialArgs = {
    inherit inputs outputs vlib;
  };
  modules = [
    ./home.nix
  ];
}
