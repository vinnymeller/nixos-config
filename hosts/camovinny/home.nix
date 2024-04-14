{
  inputs,
  outputs,
  pkgs,
  ...
}: let
  cust_pkgs = import ../../pkgs {inherit pkgs;};
in {
  imports = [
    ../../programs/zsh
    ../../programs/git
    ../../programs/tmux
    ../../programs/kitty
    outputs.myNixCats.homeModule
  ];

  # nvim nightly overlay doesn't seem to work on aarch64-darwin for now. TODO look into why
  # nixpkgs.overlays = builtins.attrValues (builtins.removeAttrs outputs.overlays [ "neovim-nightly" ]);
  nixpkgs.overlays = builtins.attrValues outputs.overlays;
  nixpkgs.config = {
    allowBroken = true;
    allowUnfree = true;
  };
  nix.package = pkgs.nixFlakes;
  nix.settings.experimental-features = ["nix-command" "flakes"];
  nix.settings.auto-optimise-store = true;
  nix.settings.require-sigs = false;
  nix.settings.trusted-users = ["vinny" "root"];
  nix.settings.trusted-public-keys = ["vinnix:xCPWQjVNXvqsEJgdEhUMpmVIyJseAPAcZEm3b6HU8vk="];

  nixCats = {
    enable = true;
    packageNames = ["nixCats"];
  };

  home.packages = with pkgs; [
    gnupg
    nodejs
    vscode
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
