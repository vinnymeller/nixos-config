{
  inputs,
  outputs,
  ...
}:
inputs.nixpkgs.lib.nixosSystem {
  specialArgs = {inherit inputs outputs;};
  modules = [
    inputs.lanzaboote.nixosModules.lanzaboote

    ({
      pkgs,
      lib,
      ...
    }: {
      environment.systemPackages = [pkgs.sbctl];

      boot.loader.systemd-boot.enable = lib.mkForce false;

      boot.lanzaboote = {
        enable = true;
        pkiBundle = "/etc/secureboot";
      };
    })

    inputs.nix-index-database.nixosModules.nix-index

    # { nixpkgs.overlays = outputs.overlays; }
    ./configuration.nix
    ./hardware.nix
    inputs.home-manager.nixosModules.home-manager
    {
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.users.vinny = import ./users/vinny/home.nix;
      home-manager.extraSpecialArgs = {inherit inputs outputs;};
    }
  ];
}
