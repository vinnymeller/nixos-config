{ pkgs, ... }:

with pkgs;

writeShellApplication {
  name = "gh-clone-all";
  runtimeInputs = [
    bash
    gh
  ];

  text = builtins.readFile ../../scripts/gh-clone-all.sh;
}
