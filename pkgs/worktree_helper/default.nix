{ pkgs, ... }:

with pkgs;

writeShellApplication {
    name = "worktree_helper";
    runtimeInputs = [
        bash
        coreutils
        gawk
        git
        fzf
        twm
    ];

    text = builtins.readFile ../../scripts/worktree_helper.sh;
}
