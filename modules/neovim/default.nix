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
            barbar-nvim
            catppuccin-nvim
            cmp-buffer
            cmp-git
            cmp-nvim-lsp
            cmp-nvim-lsp-signature-help
            cmp-nvim-lua
            cmp-path
            cmp_luasnip
            comment-nvim
            copilot-lua
            diffview-nvim
            fidget-nvim
            flash-nvim
            formatter-nvim
            gitsigns-nvim
            gruvbox-nvim
            harpoon
            indent-blankline-nvim
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
            nvim-web-devicons
            plenary-nvim
            rust-tools-nvim
            sniprun
            telescope-nvim
            telescope-sg
            tint-nvim
            undotree
            vim-be-good
            vim-fugitive
            vim-indent-object
            vim-surround
            which-key-nvim
        ];
        extraPackages = with pkgs; [
            ast-grep
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
            stylua
            terraform-ls
        ];
    };
}
