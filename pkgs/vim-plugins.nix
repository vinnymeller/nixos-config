{ lib, buildVimPlugin, buildNeovimPlugin, fetchFromGitHub, fetchgit }:

final: prev:
{
  molten-nvim = buildVimPlugin {
    pname = "molten-nvim";
    version = "2023-10-21";
    src = fetchFromGitHub {
      owner = "benlubas";
      repo = "molten-nvim";
      rev = "f9c28efc13f7a262e27669b984f3839ff5c50c32";
      sha256 = "1r8xf3jphgml0pax34p50d67rglnq5mazdlmma1jnfkm67acxaac";
    };
    meta.homepage = "https://github.com/benlubas/molten-nvim/";
  };

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
