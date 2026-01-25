{ pkgs, ... }:

with pkgs;

writeShellApplication {
  name = "find-file-up-tree";
  text = builtins.readFile ./find-file-up-tree.sh;
}
