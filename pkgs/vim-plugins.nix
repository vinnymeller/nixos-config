{ lib, buildVimPlugin, buildNeovimPlugin, fetchFromGitHub, fetchgit }:

final: prev: {
  leetcode-nvim = buildVimPlugin {
    pname = "leetcode.nvim";
    version = "2023-11-10";
    src = fetchFromGitHub {
      owner = "kawre";
      repo = "leetcode.nvim";
      rev = "0a0ab1a67fa96ff82f16c44febb4786bb0cf288d";
      sha256 = "1vlm2mxhvlc9nw66k2mxd3mpadvl7gjj8h79np35rzi2arsv60s4";
    };
    meta.homepage = "https://github.com/kawre/leetcode.nvim/";
  };

}
