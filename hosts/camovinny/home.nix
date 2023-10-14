{ inputs, outputs, pkgs, ... }:
let
  cust_pkgs = import ../../pkgs { inherit pkgs; };
in
{
  imports = [
    ../../modules/neovim
    ../../modules/zsh
    ../../modules/git
    ../../modules/tmux
    ../../modules/kitty
  ];


  # nvim nightly overlay doesn't seem to work on aarch64-darwin for now. TODO look into why
  nixpkgs.overlays = builtins.attrValues (builtins.removeAttrs outputs.overlays [ "neovim-nightly" ]);
  nix.package = pkgs.nixFlakes;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.settings.auto-optimise-store = true;

  home.packages = with pkgs; [
    gnupg
    cust_pkgs.kill_and_attach
    cust_pkgs.worktree_helper
    cust_pkgs.find_file_up_tree
  ];

  programs.direnv.enable = true;
  programs.direnv.nix-direnv.enable = true;

  home.username = "vinny";
  home.homeDirectory = "/Users/vinny";
  home.stateVersion = "22.11";

  programs.home-manager.enable = true;
}
