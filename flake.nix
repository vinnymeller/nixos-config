{
  description = "Vinny's NixOS Configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    nixpkgs-master.url = "github:NixOS/nixpkgs/master";

    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-25.05";

    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL/main";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-compat.follows = "flake-compat";
      };
    };

    hyprland = {
      url = "github:hyprwm/Hyprland";
      inputs = {
        pre-commit-hooks.follows = "git-hooks";
        nixpkgs.follows = "nixpkgs";
      };
    };

    crane = {
      url = "github:ipetkov/crane";
    };

    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };

    flake-parts.url = "github:hercules-ci/flake-parts";
    hercules-ci-effects = {
      url = "github:hercules-ci/hercules-ci-effects";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-parts.follows = "flake-parts";
      };
    };

    blink-cmp = {
      url = "github:Saghen/blink.cmp";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-parts.follows = "flake-parts";
        fenix.follows = "fenix";
      };
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyper-mcp = {
      url = "github:vinnymeller/nix-hyper-mcp";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        rust-overlay.follows = "rust-overlay";
        crane.follows = "crane";
      };
    };

    lanzaboote = {
      url = "github:nix-community/lanzaboote";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        crane.follows = "crane";
        rust-overlay.follows = "rust-overlay";
        flake-compat.follows = "flake-compat";
        flake-parts.follows = "flake-parts";
      };
    };

    flake-utils.url = "github:numtide/flake-utils";

    agenix = {
      url = "github:ryantm/agenix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        home-manager.follows = "home-manager";
      };
    };
    ragenix = {
      url = "github:yaxitech/ragenix";
      inputs = {
        agenix.follows = "agenix";
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
        crane.follows = "crane";
        rust-overlay.follows = "rust-overlay";
      };
    };

    github-nix-ci = {
      url = "github:juspay/github-nix-ci";
    };

    nixCats.url = "github:BirdeeHub/nixCats-nvim";

    neovim-nightly-overlay = {
      url = "github:nix-community/neovim-nightly-overlay";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        hercules-ci-effects.follows = "hercules-ci-effects";
        git-hooks.follows = "git-hooks";
        flake-parts.follows = "flake-parts";
        flake-compat.follows = "flake-compat";
      };
    };

    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-compat.follows = "flake-compat";
      };
    };

    avante-nvim = {
      url = "github:vinnymeller/avante-nvim-nightly-flake";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
      };
    };

    twm = {
      url = "github:vinnymeller/twm";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
      inputs.rust-overlay.follows = "rust-overlay";
    };

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };

  outputs =
    inputs@{
      self,
      flake-utils,
      nixpkgs,
      ...
    }:
    let
      inherit (self) outputs;

      forAllSystems = nixpkgs.lib.genAttrs flake-utils.lib.defaultSystems; # change this if i need some weird systems

      myNixCats = import ./programs/ncvim { inherit inputs; };
    in
    {
      myNixCats = myNixCats;

      packages =
        forAllSystems (
          system:
          let
            pkgs = nixpkgs.legacyPackages.${system};
          in
          import ./pkgs { inherit pkgs; }
        )
        // myNixCats.packages;

      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        import ./shell.nix { inherit pkgs; }
      );

      overlays = import ./overlays { inherit inputs; };

      nixosConfigurations = {
        vinnix = import ./hosts/vinnix { inherit inputs outputs; };
        vindows = import ./hosts/home-wsl { inherit inputs outputs; };
      };
      homeConfigurations = {
        vinny = import ./hosts/camovinny { inherit inputs outputs; };
        amina = import ./hosts/amina { inherit inputs outputs; };
      };
    };
}
