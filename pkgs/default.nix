{ pkgs }:
with pkgs;
{
  build-nix-pkg-update = callPackage ./build-nix-pkg-update { };
  check-duplicate-flake-deps = callPackage ./check-duplicate-flake-deps { };
  gh-clone-all = callPackage ./gh-clone-all { };
  tmux-kill-and-attach = callPackage ./tmux-kill-and-attach { };
  worktree-helper = callPackage ./worktree-helper { };
  find-file-up-tree = callPackage ./find-file-up-tree { };
  swap-audio-output = callPackage ./swap-audio-output { };
}
