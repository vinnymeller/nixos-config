{ pkgs, ... }:

with pkgs;

writeShellApplication {
  name = "tmux-kill-and-attach";
  runtimeInputs = [
    bash
    tmux
  ];
  text = builtins.readFile ../../scripts/tmux-kill-and-attach.sh;
}
