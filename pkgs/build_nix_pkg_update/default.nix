{ pkgs, ... }:

with pkgs;

writeShellApplication {
  name = "build_nix_pkg_update";
  runtimeInputs = [
    bash
    git
  ];

  text = builtins.readFile ../../scripts/build_nix_pkg_update.sh;
}
