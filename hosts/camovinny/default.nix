{
  inputs,
  outputs,
  vlib,
  pkgs,
  ...
}:
inputs.home-manager.lib.homeManagerConfiguration {
  inherit pkgs;
  extraSpecialArgs = {
    inherit inputs outputs vlib;
  };
  modules = [
    ./home.nix
  ];
}
