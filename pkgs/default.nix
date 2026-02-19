{ pkgs }:
with pkgs;
{
  build-nix-pkg-update = callPackage ./build-nix-pkg-update { };
  check-duplicate-flake-deps = callPackage ./check-duplicate-flake-deps { };
  find-file-up-tree = callPackage ./find-file-up-tree { };
  gh-clone-all = callPackage ./gh-clone-all { };
  rofi-chrome-profile-launcher = callPackage ./rofi-chrome-profile-launcher { };
  swap-audio-output = callPackage ./swap-audio-output { };
  tmux-kill-and-attach = callPackage ./tmux-kill-and-attach { };
  vtt = callPackage ./vtt { };
  worktree-helper = callPackage ./worktree-helper { };
}
