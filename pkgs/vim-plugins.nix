{
  lib,
  buildVimPlugin,
  buildNeovimPlugin,
  fetchFromGitHub,
  fetchgit,
}: final: prev: {
  leetcode-nvim = buildVimPlugin {
    pname = "leetcode.nvim";
    version = "unstable-2024-04-06";
    src = fetchFromGitHub {
      owner = "kawre";
      repo = "leetcode.nvim";
      rev = "a92e764cda74331789210c6ff6587bf269e0ffaf";
      sha256 = "sha256-bT3XVu7LP/HjCdXHjBLmCiskvG4swiBWbYAgwfIDkF0=";
    };
    meta.homepage = "https://github.com/kawre/leetcode.nvim/";
  };
}
