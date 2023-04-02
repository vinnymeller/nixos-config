{ config, pkgs, ...}: {

    programs.neovim.enable = true;
    home.sessionVariables = {
        EDITOR = "nvim";
    };

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

    home.shellAliases = {
        nvim = "nvim -u ~/.nixdots/dotfiles/nvim/init.lua";
    };
}
