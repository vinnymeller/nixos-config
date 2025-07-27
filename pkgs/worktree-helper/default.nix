{ pkgs, ... }:

with pkgs;

writeShellApplication {
  name = "worktree-helper";
  runtimeInputs = [
    bash
    coreutils
    gawk
    git
    fzf
    twm
  ];

  text = builtins.readFile ../../scripts/worktree-helper.sh;
}
