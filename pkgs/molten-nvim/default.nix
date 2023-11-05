{ pkgs, ... }:

with pkgs;

vimUtils.buildVimPlugin {
    pname = "molten-nvim";
    version = "2023-10-21";
    src = fetchFromGitHub {
      owner = "benlubas";
      repo = "molten-nvim";
      rev = "f9c28efc13f7a262e27669b984f3839ff5c50c32";
      sha256 = "1r8xf3jphgml0pax34p50d67rglnq5mazdlmma1jnfkm67acxaac";
    };
    meta.homepage = "https://github.com/benlubas/molten-nvim/";
}
