{ pkgs, ... }:

with pkgs;

writeShellApplication {
  name = "build-nix-pkg-update";
  runtimeInputs = [
    bash
    git
  ];

  text = builtins.readFile ../../scripts/build-nix-pkg-update.sh;
}
