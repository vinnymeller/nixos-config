{ pkgs, ... }:

with pkgs;

writeShellApplication {
  name = "gh_clone_all";
  runtimeInputs = [
    bash
    gh
  ];

  text = builtins.readFile ../../scripts/gh_clone_all.sh;
}
