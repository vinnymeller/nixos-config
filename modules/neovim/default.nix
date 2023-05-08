{ config, pkgs, ...}: {


    home.file.".config/nvim" = {
        source = ../../dotfiles/nvim;
        recursive = true;
    };

    home.shellAliases = {
        nvimt = "nvim -u ~/.nixdots/dotfiles/nvim/init.lua"; # to test new config without rebuilding
    };
    programs.neovim = {
        enable = true;
        defaultEditor = true;
        plugins = with pkgs.vimPlugins; [
            autosave-nvim
            catppuccin-nvim
            cmp-buffer
            cmp-git
            cmp-nvim-lsp
            cmp-nvim-lua
            cmp-path
            cmp_luasnip
            comment-nvim
            copilot-lua
            diffview-nvim
            fidget-nvim
            formatter-nvim
            gitsigns-nvim
            gruvbox-nvim
            indent-blankline-nvim
            leap-nvim
            lualine-nvim
            luasnip
            markdown-preview-nvim
            neorg
            nvim-autopairs
            nvim-cmp
            nvim-lspconfig
            nvim-treesitter-context
            nvim-treesitter-textobjects
            nvim-treesitter.withAllGrammars
            plenary-nvim
            rust-tools-nvim
            sniprun
            telescope-nvim
            tint-nvim
            undotree
            vim-be-good
            vim-fugitive
            vim-indent-object
            vim-surround
            which-key-nvim
        ];
        extraPackages = with pkgs; [
            black
            isort
            libclang
            lua-language-server
            nil
            nodePackages.pyright
            nodePackages.typescript-language-server
            nodePackages.yaml-language-server
            nodejs
            ripgrep
            rust-analyzer
            shfmt
            terraform-ls
        ];
    };
}
