{ pkgs, ... }:

with pkgs;

writeShellApplication {
  name = "kill_and_attach";
  runtimeInputs = [
    bash
    tmux
  ];
  text = builtins.readFile ../../scripts/kill_and_attach.sh;
}
