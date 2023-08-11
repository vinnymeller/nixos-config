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

    # master-pkgs-overlay = self: super: {
    #     master-pkgs = nixpkgs-master.legacyPackages.${super.system};
    # };
    #
    #
    # overlays = [
    #     master-pkgs-overlay
    #     neovim-nightly-overlay.overlay
    # ];

    in {

        # TOOD: come back to this later. some of my packages don't work on mac, so what's the most elegant way to do this?
        # packages = forAllSystems (system:
        #     let
        #         pkgs = nixpkgs.legacyPackages.${system};
        #     in import ./pkgs { inherit pkgs; }
        # );
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
            vinny = import ./hosts/wdtech-eos { inherit inputs outputs; };
            vmeller = import ./hosts/work-laptop { inherit inputs outputs; };
        };
  };
}
