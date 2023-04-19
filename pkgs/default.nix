{ pkgs }:
with pkgs; {
    kill_and_attach = callPackage ./kill_and_attach { };
    screenshot_to_clipboard = callPackage ./screenshot_to_clipboard { };
    worktree_helper = callPackage ./worktree_helper { };
}
