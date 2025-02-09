{ inputs, outputs, ... }:

inputs.nixpkgs.lib.nixosSystem {
  specialArgs = {
    inherit inputs outputs;
  };
  modules = [
    ./configuration.nix
    inputs.nixos-wsl.nixosModules.default {
      system.stateVersion = "24.05";
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
        inherit inputs outputs;
      };
    }
  ];
}
