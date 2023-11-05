{ config, pkgs, ... }: 
let
  cust_pkgs = import ../../pkgs { inherit pkgs; };
in
{


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
      cust_pkgs.molten-nvim
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
      neogit
      nvim-autopairs
      nvim-cmp
      nvim-lspconfig
      nvim-treesitter-context
      nvim-treesitter-textobjects
      nvim-treesitter.withAllGrammars
      nvim-web-devicons
      pkgs.master-pkgs.vimPlugins.nvim-remote-containers
      pkgs.master-pkgs.vimPlugins.telescope-sg
      plenary-nvim
      rust-tools-nvim
      sniprun
      telescope-nvim
      tint-nvim
      undotree
      vim-be-good
      vim-dadbod
      vim-dadbod-completion
      vim-dadbod-ui
      vim-fugitive
      vim-indent-object
      vim-matchup
      vim-surround
      which-key-nvim
      wilder-nvim
      zk-nvim
    ];

    extraPackages = with pkgs; [
      ast-grep
      black
      gcc
      haskellPackages.haskell-language-server
      stable-pkgs.imagemagick
      isort
      libclang
      ltex-ls
      lua-language-server
      nil
      nodePackages.pyright
      nodePackages.typescript-language-server
      nodePackages.yaml-language-server
      nodejs
      ocamlPackages.ocaml-lsp
      pgformatter
      postgresql
      ripgrep
      rust-analyzer
      shfmt
      stylua
      terraform-ls
      xsel
      zk
    ];

    extraLuaPackages = ps: [
      pkgs.master-pkgs.luajitPackages.magick
    ];

    extraPython3Packages = pyPkgs: with pyPkgs; [
      pynvim
      jupyter-client
      cairosvg
      pnglatex
      plotly
      pyperclip
    ];
  };
}
