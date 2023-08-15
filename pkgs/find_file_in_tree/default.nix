{ pkgs, ... }:

with pkgs;

writeShellApplication {
    name = "find_file_up_tree";
    text = builtins.readFile ../../scripts/find_file_up_tree.sh;
}
