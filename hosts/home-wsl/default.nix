{
  inputs,
  outputs,
  vlib,
  pkgs,
  ...
}:

inputs.nixpkgs.lib.nixosSystem {
  inherit pkgs;
  specialArgs = {
    inherit inputs outputs vlib;
  };
  modules = [
    ./configuration.nix
    inputs.nixos-wsl.nixosModules.default
    {
      system.stateVersion = "25.11";
      wsl.enable = true;
      wsl.defaultUser = "vinny";
    }
    inputs.ragenix.nixosModules.default
    inputs.github-nix-ci.nixosModules.default
    inputs.home-manager.nixosModules.home-manager
    {
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.users.vinny = import ./home.nix;
      home-manager.extraSpecialArgs = {
        inherit inputs outputs vlib;
      };
    }
  ];
}
