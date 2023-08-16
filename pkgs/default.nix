{ pkgs }:
with pkgs; {
    discord_audio_share = callPackage ./discord_audio_share { };
    kill_and_attach = callPackage ./kill_and_attach { };
    screenshot_to_clipboard = callPackage ./screenshot_to_clipboard { };
    worktree_helper = callPackage ./worktree_helper { };
    find_file_up_tree = callPackage ./find_file_up_tree { };
}
