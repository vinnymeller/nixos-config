{ config, pkgs, ...}: {

    programs.neovim.enable = true;
    home.file.".config/nvim".source = ../../dotfiles/nvim;

    home.packages = with pkgs; [
        ripgrep
        nodejs-19_x
        rust-analyzer
        haskell-language-server
        ghc
        lua-language-server
        nil
        libclang
    ];

}
