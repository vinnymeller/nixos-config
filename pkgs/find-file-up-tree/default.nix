{ pkgs, ... }:

with pkgs;

writeShellApplication {
  name = "find-file-up-tree";
  text = builtins.readFile ../../scripts/find-file-up-tree.sh;
}
