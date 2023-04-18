{ pkgs }:
with pkgs; {
    screenshot_to_clipboard = callPackage ./screenshot_to_clipboard { };
    worktree_helper = callPackage ./worktree_helper { };
}
