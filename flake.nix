{
  description = "Vinny's NixOS Configuration";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    nixpkgs-master.url = "github:NixOS/nixpkgs/master";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
  };

  outputs = inputs@{ self, nixpkgs, nixpkgs-master, neovim-nightly-overlay, home-manager, ... }:
  let
    master-pkgs-overlay = self: super: {
        master-pkgs = nixpkgs-master.legacyPackages.${super.system};
    };
    in
  {
    nixosConfigurations = {
        vinnix = import ./hosts/vinnix { inherit master-pkgs-overlay neovim-nightly-overlay nixpkgs home-manager; };
    };
    homeConfigurations = {
        vinny = import ./hosts/wdtech-eos { inherit nixpkgs home-manager; };
    };
  };
}
