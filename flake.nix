{
  description = "Vinny's NixOS Configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    nixpkgs-master.url = "github:NixOS/nixpkgs/master";

    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-25.05";

    wrapper-modules = {
      url = "github:BirdeeHub/nix-wrapper-modules";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    claude-plugins-official = {
      url = "github:anthropics/claude-plugins-official";
      flake = false;
    };

    claude-plugins-superpowers = {
      url = "github:obra/superpowers";
      flake = false;
    };

    systems.url = "github:nix-systems/default";

    rsvpub = {
      url = "github:vinnymeller/rsvpub";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        systems.follows = "systems";
      };
    };

    nix-std.url = "github:chessai/nix-std";

    llm-agents = {
      url = "github:numtide/llm-agents.nix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        blueprint.follows = "blueprint";
      };
    };

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

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    lanzaboote = {
      url = "github:nix-community/lanzaboote";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        crane.follows = "crane";
        rust-overlay.follows = "rust-overlay";
      };
    };

    blueprint = {
      url = "github:numtide/blueprint";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        systems.follows = "systems";
      };
    };

    flake-utils = {
      url = "github:numtide/flake-utils";
      inputs.systems.follows = "systems";
    };

    agenix = {
      url = "github:ryantm/agenix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        home-manager.follows = "home-manager";
        systems.follows = "systems";
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
      url = "github:vinnymeller/github-nix-ci";
    };

    neovim-nightly-overlay = {
      url = "github:nix-community/neovim-nightly-overlay";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-parts.follows = "flake-parts";
      };
    };

    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-compat.follows = "flake-compat";
      };
    };

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      home-manager,
      systems,
      ...
    }:
    let
      inherit (self) outputs;
      inherit (nixpkgs) lib;

      eachSystem = lib.genAttrs (import systems);

      pkgsFor = eachSystem (
        system:
        import nixpkgs {
          localSystem = system;
          overlays = self.overlayList;
          config.allowUnfree = true;
        }
      );

      vlib = import ./lib {
        lib = nixpkgs.lib;
        hmLib = home-manager.lib;
      };
    in
    {

      lib.vlib = vlib;

      formatter = eachSystem (system: pkgsFor.${system}.nixfmt);

      packages = eachSystem (
        system:
        let
          pkgs = pkgsFor.${system};
        in
        {
          neovim = pkgs.neovim;
          claude-code = pkgs.claude-code;
        }
      );

      devShells = eachSystem (system: import ./shell.nix { pkgs = pkgsFor.${system}; });

      overlays = import ./overlays { inherit inputs vlib; };

      overlayList = builtins.attrValues self.overlays;

      nixosConfigurations = {
        vinnix = import ./hosts/vinnix {
          inherit inputs outputs;
          inherit (self.lib) vlib;
        };
        vindows = import ./hosts/home-wsl {
          inherit inputs outputs;
          inherit (self.lib) vlib;
        };
      };
      homeConfigurations = {
        vinny = import ./hosts/camovinny {
          inherit inputs outputs;
          inherit (self.lib) vlib;
          pkgs = pkgsFor."aarch64-darwin";
        };
      };
    };
}
