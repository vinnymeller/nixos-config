{ pkgs }:
with pkgs;
{
  build_nix_pkg_update = callPackage ./build_nix_pkg_update { };
  discord_audio_share = callPackage ./discord_audio_share { };
  gh_clone_all = callPackage ./gh_clone_all { };
  kill_and_attach = callPackage ./kill_and_attach { };
  worktree_helper = callPackage ./worktree_helper { };
  find_file_up_tree = callPackage ./find_file_up_tree { };
}
