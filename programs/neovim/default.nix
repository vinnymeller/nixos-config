{ lib, config, pkgs, ... }:
let
  custom-vim-plugins = pkgs.vimPlugins.extend
    ((pkgs.callPackage ../../pkgs/vim-plugins.nix {
      inherit (pkgs.vimUtils) buildVimPlugin;
      inherit (pkgs.neovimUtils) buildNeovimPlugin;
    }));
in {

  home.file.".config/nvim" = {
    source = ../../dotfiles/nvim;
    recursive = true;
  };

  home.shellAliases = { leetcode = "nvim leetcode.nvim"; };
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    withPython3 = true;
    withNodeJs = true;
    plugins = with pkgs.vimPlugins; [
      SchemaStore-nvim
      autosave-nvim
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
      custom-vim-plugins.leetcode-nvim
      diffview-nvim
      fidget-nvim
      flash-nvim
      formatter-nvim
      gitsigns-nvim
      gruvbox-nvim
      image-nvim
      indent-blankline-nvim
      lspkind-nvim
      lualine-nvim
      luasnip
      markdown-preview-nvim
      molten-nvim
      neogit
      nui-nvim
      nvim-autopairs
      nvim-cmp
      nvim-lspconfig
      nvim-treesitter-context
      nvim-treesitter-textobjects
      nvim-treesitter.withAllGrammars
      nvim-ts-autotag
      nvim-web-devicons
      oil-nvim
      pkgs.master-pkgs.vimPlugins.nvim-remote-containers
      pkgs.master-pkgs.vimPlugins.telescope-sg
      plenary-nvim
      rustaceanvim
      sg-nvim
      sniprun
      telescope-fzf-native-nvim
      telescope-nvim
      tint-nvim
      tmux-nvim
      undotree
      vim-be-good
      vim-dadbod
      vim-dadbod-completion
      vim-dadbod-ui
      vim-fugitive
      vim-indent-object
      vim-matchup
      vim-sleuth
      vim-surround
      which-key-nvim
      wilder-nvim
      zk-nvim
    ];

    extraPackages = with pkgs;
      [
        ast-grep
        black
        cargo
        dockerfile-language-server-nodejs
        fd
        gcc
        haskellPackages.haskell-language-server
        isort
        libclang
        ltex-ls
        lua-language-server
        nil
        nixfmt
        nodePackages.pyright
        nodePackages.typescript-language-server
        nodejs
        ocamlPackages.ocaml-lsp
        pgformatter
        postgresql
        prettierd
        ripgrep
        rust-analyzer
        shfmt
        src-cli
        imagemagick
        stylua
        tailwindcss-language-server
        terraform-ls
        vscode-langservers-extracted
        xsel
        yaml-language-server
        zk
      ] ++ (if stdenv.isLinux then
        [ master-pkgs.htmx-lsp ]
      else
        [ ]); # do this until i can get htmx lsp to build on darwin

    extraLuaPackages = ps: with ps; [ magick ];

    extraPython3Packages = pyPkgs:
      with pyPkgs; [
        cairosvg
        jupyter-client
        nbformat
        plotly
        pnglatex
        pynvim
        pyperclip
      ];
  };
}
