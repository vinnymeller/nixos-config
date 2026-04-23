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

    claude-cowork-service = {
      url = "github:patrickjaja/claude-cowork-service";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };

    claude-desktop = {
      url = "github:patrickjaja/claude-desktop-bin";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };

    claude-plugins-official = {
      url = "github:anthropics/claude-plugins-official";
      flake = false;
    };

    systems.url = "github:nix-systems/default";

    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL/main";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-compat.follows = "flake-compat";
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

    # use their nixpkgs to pull from cache
    llm-agents = {
      url = "github:numtide/llm-agents.nix";
      inputs = {
        blueprint.follows = "blueprint";
        flake-parts.follows = "flake-parts";
        systems.follows = "systems";
      };
    };

    hyprland = {
      url = "github:hyprwm/Hyprland";
      inputs = {
        pre-commit-hooks.follows = "git-hooks";
      };
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

      mkPkgs =
        system: extraConfig:
        import nixpkgs {
          localSystem = system;
          overlays = builtins.attrValues self.overlays;
          config = {
            allowUnfree = true;
          }
          // extraConfig;
        };

      vlib = import ./lib {
        lib = nixpkgs.lib;
        hmLib = home-manager.lib;
      };

      perSystem =
        f:
        let
          _results = lib.genAttrs (import systems) f;
          _outputs = builtins.attrNames (builtins.head (builtins.attrValues _results));
        in
        lib.genAttrs _outputs (name: lib.mapAttrs (_: systemResults: systemResults.${name}) _results);
    in
    {

      lib.vlib = vlib;

      overlays = import ./overlays { inherit inputs vlib; };

      nixosConfigurations = {
        vinnix = import ./hosts/vinnix {
          inherit inputs outputs;
          inherit (self.lib) vlib;
          pkgs = mkPkgs "x86_64-linux" { cudaSupport = true; };
        };
        vindows = import ./hosts/home-wsl {
          inherit inputs outputs;
          inherit (self.lib) vlib;
          pkgs = mkPkgs "x86_64-linux" { };
        };
      };

      homeConfigurations = {
        vinny = import ./hosts/camovinny {
          inherit inputs outputs;
          inherit (self.lib) vlib;
          pkgs = mkPkgs "aarch64-darwin" { };
        };
        mini = import ./hosts/mini {
          inherit inputs outputs;
          inherit (self.lib) vlib;
          pkgs = mkPkgs "aarch64-darwin" { };
        };
      };
    }
    // perSystem (
      system:
      let
        pkgs = mkPkgs system { };
      in
      {
        formatter = pkgs.nixfmt-tree;
        packages = { inherit (pkgs) neovim claude-code; };
        devShells = import ./shell.nix { inherit pkgs; };
        checks =
          lib.mapAttrs' (name: nixos: lib.nameValuePair "eval-${name}" nixos.config.system.build.toplevel)
            (
              lib.filterAttrs (_: nixos: nixos.pkgs.stdenv.hostPlatform.system == system) self.nixosConfigurations
            );
      }
    );
}
