{
  inputs,
  outputs,
  myUtils,
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
    inherit inputs outputs myUtils;
  };
  modules = [
    ./home.nix
  ];
}
