{
  description = "Vinny's NixOS Configuration";

  inputs = {

    nixpkgs.url = "nixpkgs/nixos-unstable";

    nixpkgs-master.url = "github:NixOS/nixpkgs/master";

    home-manager = {
        url = "github:nix-community/home-manager";
        inputs.nixpkgs.follows = "nixpkgs";
    };

    neovim-nightly-overlay = {
        url = "github:nix-community/neovim-nightly-overlay";
        inputs.nixpkgs.follows = "nixpkgs";
    };

    lanzaboote = {
        url = "github:nix-community/lanzaboote";
        inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-utils.url = "github:numtide/flake-utils";

  };

  outputs = inputs@{ self, flake-utils, nixpkgs, nixpkgs-master, neovim-nightly-overlay, home-manager, lanzaboote, ... }:
  let

    inherit (self) outputs;

    forAllSystems = nixpkgs.lib.genAttrs flake-utils.lib.defaultSystems; # change this if i need some weird systems

    in {

        defaultPackage = forAllSystems (system: home-manager.defaultPackage.${system} );

        packages = forAllSystems (system:
            let pkgs = nixpkgs.legacyPackages.${system};
            in import ./pkgs { inherit pkgs; }
        );

        devShells = forAllSystems (system:
            let pkgs = nixpkgs.legacyPackages.${system};
            in import ./shell.nix { inherit pkgs; }
        );

        overlays = import ./overlays { inherit inputs; };

        nixosConfigurations = {
            vinnix = import ./hosts/vinnix { inherit inputs outputs; };
            home-nix-wsl = import ./hosts/home-wsl { inherit inputs outputs; };
        };
        homeConfigurations = {
            "vinny@wdtech-eos" = import ./hosts/wdtech-eos { inherit inputs outputs; };
        };
  };
}
