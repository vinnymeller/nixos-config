{
  description = "Vinny's NixOS Configuration";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    nixpkgs-master.url = "github:NixOS/nixpkgs/master";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";

    lanzaboote = {
        url = "github:nix-community/lanzaboote";
        inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nixpkgs, nixpkgs-master, neovim-nightly-overlay, home-manager, lanzaboote, ... }:
  let
    master-pkgs-overlay = self: super: {
        master-pkgs = nixpkgs-master.legacyPackages.${super.system};
    };


    overlays = [
        master-pkgs-overlay
        neovim-nightly-overlay.overlay
    ];

    in
  {
    defaultPackage.x86_64-linux = home-manager.defaultPackage.x86_64-linux;
    defaultPackage.x86_64-darwin = home-manager.defaultPackage.x86_64-darwin;

    nixosConfigurations = {
        vinnix = import ./hosts/vinnix { inherit nixpkgs home-manager lanzaboote overlays; };
        home-nix-wsl = import ./hosts/home-wsl { inherit nixpkgs home-manager overlays; };
    };
    homeConfigurations = {
        vinny = import ./hosts/wdtech-eos { inherit nixpkgs home-manager overlays; };
        vmeller = import ./hosts/work-laptop { inherit nixpkgs home-manager overlays; };
    };
  };
}
