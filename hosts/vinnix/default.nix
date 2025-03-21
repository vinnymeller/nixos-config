{ inputs, outputs, ... }:
inputs.nixpkgs.lib.nixosSystem {
  specialArgs = {
    inherit inputs outputs;
  };
  modules = [
    inputs.ragenix.nixosModules.default
    inputs.lanzaboote.nixosModules.lanzaboote

    (
      { pkgs, lib, ... }:
      {
        environment.systemPackages = [ pkgs.sbctl ];

        # Lanzaboote currently replaces the systemd-boot module.
        # This setting is usually set to true in configuration.nix
        # generated at installation time. So we  force it to false
        # for now.
        boot.loader.systemd-boot.enable = lib.mkForce false;

        boot.lanzaboote = {
          enable = true;
          pkiBundle = "/var/lib/sbctl";
        };
      }
    )

    # { nixpkgs.overlays = outputs.overlays; }
    ./configuration.nix
    ./hardware.nix
    inputs.home-manager.nixosModules.home-manager
    {
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.users.vinny = import ./users/vinny/home.nix;
      home-manager.extraSpecialArgs = {
        inherit inputs outputs;
      };
    }
  ];
}
