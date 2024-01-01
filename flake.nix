{
  description = "Vinny's NixOS Configuration";

  inputs = {

    nixpkgs.url = "nixpkgs/nixos-unstable";

    nixpkgs-staging.url = "github:NixOS/nixpkgs/staging";

    nixpkgs-master.url = "github:NixOS/nixpkgs/master";

    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-23.05";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-index-database = {
      url = "github:Mic92/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";

    lanzaboote = {
      url = "github:nix-community/lanzaboote";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-utils.url = "github:numtide/flake-utils";

  };

  outputs = inputs@{ self, flake-utils, nixpkgs, nixpkgs-master, nixpkgs-stable
    , neovim-nightly-overlay, nix-index-database, home-manager, lanzaboote, ...
    }:
    let

      inherit (self) outputs;

      forAllSystems = nixpkgs.lib.genAttrs
        flake-utils.lib.defaultSystems; # change this if i need some weird systems

    in {

      defaultPackage =
        forAllSystems (system: home-manager.defaultPackage.${system});

      packages = forAllSystems (system:
        let pkgs = nixpkgs.legacyPackages.${system};
        in import ./pkgs { inherit pkgs; });

      devShells = forAllSystems (system:
        let pkgs = nixpkgs.legacyPackages.${system};
        in import ./shell.nix { inherit pkgs; });

      overlays = import ./overlays { inherit inputs; };

      nixosConfigurations = {
        vinnix = import ./hosts/vinnix { inherit inputs outputs; };
        vindows = import ./hosts/home-wsl { inherit inputs outputs; };
      };
      homeConfigurations = {
        "vinny@wdtech-eos" =
          import ./hosts/wdtech-eos { inherit inputs outputs; };
        "vinny@camovinny" =
          import ./hosts/camovinny { inherit inputs outputs; };
      };
    };
}
