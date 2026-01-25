{ pkgs, ... }:

with pkgs;

writeShellApplication {
  name = "gh-clone-all";
  runtimeInputs = [
    bash
    gh
  ];

  text = builtins.readFile ./gh-clone-all.sh;
}
