{ pkgs, ... }:

with pkgs;

writeShellApplication {
  name = "build-nix-pkg-update";
  runtimeInputs = [
    bash
    git
  ];

  text = builtins.readFile ./build-nix-pkg-update.sh;
}
