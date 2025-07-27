{ pkgs, ... }:

with pkgs;

writeShellApplication {
  name = "check-duplicate-flake-deps";
  runtimeInputs = [
    bash
    jq
    lix
  ];

  text = builtins.readFile ../../scripts/check-duplicate-flake-deps.sh;
}
