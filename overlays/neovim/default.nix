{ inputs, vlib }:
{
  config,
  wlib,
  lib,
  pkgs,
  ...
}:
{
  imports = [ wlib.wrapperModules.neovim ];
  # choose a directory for your config.
  # this can be a string, for if you don't want nix to manage it right now.
  # but be careful, it also doesn't get provisioned by nix if it isnt in the store.
  config.settings.config_directory = ./.;
  config.package = inputs.neovim-nightly-overlay.packages.${pkgs.stdenv.hostPlatform.system}.neovim;

  # The makeWrapper options are available
  config.extraPackages =
    with pkgs;
    [
      ast-grep
      # black
      cargo
      cargo-nextest
      chafa
      efm-langserver
      fzf
      gcc
      git
      imagemagick
      # isort
      lazygit
      luajitPackages.jsregexp

      # nixd uses nixpkgs-fmt
      nixfmt

      # nodePackages.eslint
      nodePackages.sql-formatter
      nodejs
      postgresql
      prettierd
      # ty
      ruff
      ripgrep
      delta
      bat
      fd
      # rust-analyzer  # provice my own rust-analyzer in a project since it sometimes causes issues having incompatible versions
      # rustfmt  # same as above
      shellcheck
      shfmt
      stylua
      tree-sitter
      xsel
      xdg-utils
      zk
      alejandra
    ]
    ++ (vlib.sharedDeps pkgs).lsps;
  # your config/plugin specifications
  # a set of plugins or specs, which can contain a list of plugins or specs if desired.
  config.specs.general = with pkgs.vimPlugins; [
    SchemaStore-nvim
    autosave-nvim
    copilot-lua
    blink-cmp-avante
    blink-copilot
    diffview-nvim
    efmls-configs-nvim
    fidget-nvim
    friendly-snippets
    fzf-lua
    gitsigns-nvim
    gruvbox-nvim
    harpoon2
    image-nvim
    indent-blankline-nvim
    avante-nvim
    leetcode-nvim
    lspkind-nvim
    ltex_extra-nvim # goes with ltex-ls providing code action functionality for nvim (e.g. add to dict, ignore rule, etc)
    pkgs.master-pkgs.vimPlugins.lualine-nvim
    luasnip
    markdown-preview-nvim
    neotest
    nui-nvim
    nvim-autopairs
    nvim-dap
    nvim-dap-lldb
    nvim-dap-python
    nvim-dap-ui
    nvim-lspconfig
    nvim-luapad
    nvim-treesitter-context
    nvim-treesitter-textobjects
    nvim-treesitter.withAllGrammars
    nvim-ts-autotag
    nvim-various-textobjs
    nvim-web-devicons
    oil-nvim
    blink-cmp
    blink-compat
    grug-far-nvim
    vim-dadbod-completion
    plenary-nvim
    precognition-nvim
    rainbow_csv
    rustaceanvim
    snacks-nvim
    sniprun
    tailwind-tools-nvim
    tint-nvim
    tmux-nvim
    typescript-tools-nvim
    undotree
    vim-dadbod
    vim-dadbod-ui
    vim-fugitive
    neogit
    vim-indent-object
    vim-matchup
    vim-repeat
    vim-rhubarb
    vim-sleuth
    vim-surround
    which-key-nvim
    zk-nvim

  ];

  # you can name these whatever you want. These ones are named `general` and `lazy`
  # You can use the before and after fields to run them before or after other specs or spec of lists of specs
  config.specs.lazy = {
    # this `lazy = true` definition will transfer to specs in the contained DAL, if there is one.
    # This is because the definition of lazy in `config.specMods` checks `parentSpec.lazy or false`
    # the submodule type for `config.specMods` gets `parentSpec` as a `specialArg`.
    # you can define options like this too!
    lazy = true;
    # here we chose a DAL of plugins, but we can also pass a single plugin, or null
    # plugins are of type wlib.types.stringable
    data = with pkgs.vimPlugins; [
      lazydev-nvim
    ];
    # top level specs don't need to declare their dag name to be targetable.
    # so we can target general here, without adding name = "general" in the `general` spec above.
    # in fact, we didn't even need to give `general` a spec, its just a list!
    after = [ "general" ];
  };

  # These specMods are modules which modify your specs in config.specs
  # you can override defaults, or make your own options.
  config.specMods =
    { parentSpec, ... }:
    {
      config.collateGrammars = lib.mkDefault (parentSpec.collateGrammars or true);
    };
  # or, if you dont care about propagating parent values:
  # config.specMods.collateGrammars = lib.mkDefault true;

  # There are some default hosts!
  # python, ruby, and node are enabled by default
  # perl and neovide are not.

  # To add a wrapped $out/bin/${config.binName}-neovide to the resulting neovim derivation
  # config.hosts.neovide.nvim-host.enable = true;

  # If you want to install multiple neovim derivations via home.packages or environment.systemPackages
  # in order to prevent path collisions:

  # set this to true:
  # config.settings.dont_link = true;

  # and make sure these dont share values:
  # config.binName = "nvim";
  config.settings.aliases = [
    "nv"
    "ncvim"
  ];
}
