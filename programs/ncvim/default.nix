# Copyright (c) 2023 BirdeeHub
# Licensed under the MIT license
/*
# paste the inputs you don't have in this set into your main system flake.nix
# (lazy.nvim wrapper only works on unstable)
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    nixCats.url = "github:BirdeeHub/nixCats-nvim";
    nixCats.inputs.nixpkgs.follows = "nixpkgs";
    nixCats.inputs.flake-utils.follows = "flake-utils";
  };


Then call this file with:
myNixCats = import ./path/to/this/dir { inherit inputs; };
And the new variable myNixCats will contain all outputs of the normal flake format.
You can then pass them around, export them from the overall flake, etc.

The following is just the outputs function from the flake template.
*/
{inputs, ...} @ attrs: let
  inherit (inputs) flake-utils nixpkgs;
  inherit (inputs.nixCats) utils;
  luaPath = "${../../dotfiles/nvim}";
  forEachSystem = flake-utils.lib.eachSystem flake-utils.lib.allSystems;
  # the following extra_pkg_config contains any values
  # which you want to pass to the config set of nixpkgs
  # import nixpkgs { config = extra_pkg_config; inherit system; }
  # will not apply to module imports
  # as that will have your system values
  extra_pkg_config = {
    allowUnfree = true;
  };
  inherit
    (forEachSystem (system: let
      # see :help nixCats.flake.outputs.overlays
      # This overlay grabs all the inputs named in the format
      # `plugins-<pluginName>`
      # Once we add this overlay to our nixpkgs, we are able to
      # use `pkgs.neovimPlugins`, which is a set of our plugins.
      dependencyOverlays = [
        (utils.mergeOverlayLists inputs.nixCats.dependencyOverlays.${system}
          ((import ./overlays inputs)
            ++ [
              (utils.standardPluginOverlay inputs)
              # add any flake overlays here.
            ]))
      ];
    in {inherit dependencyOverlays;}))
    dependencyOverlays
    ;

  categoryDefinitions = {
    pkgs,
    settings,
    categories,
    name,
    ...
  } @ packageDef: let
    custom-vim-plugins =
      pkgs.vimPlugins.extend
      (pkgs.callPackage ../../pkgs/vim-plugins.nix {
        inherit (pkgs.vimUtils) buildVimPlugin;
        inherit (pkgs.neovimUtils) buildNeovimPlugin;
      });
  in {
    propagatedBuildInputs = {
      generalBuildInputs = with pkgs; [
      ];
    };

    lspsAndRuntimeDeps = {
      general = with pkgs;
        [
          alejandra
          ast-grep
          black
          cargo
          dockerfile-language-server-nodejs
          efm-langserver
          fd
          gcc
          haskellPackages.haskell-language-server
          imagemagick
          isort
          libclang
          ltex-ls
          lua-language-server
          nil
          nixfmt
          nodePackages.pyright
          nodePackages.sql-formatter
          nodePackages.typescript-language-server
          nodejs
          ocamlPackages.ocaml-lsp
          postgresql
          prettierd
          ripgrep
          rust-analyzer
          shellcheck
          shfmt
          src-cli
          stylua
          tailwindcss-language-server
          terraform-ls
          vscode-langservers-extracted
          xsel
          yaml-language-server
          zk
        ]
        ++ (
          if stdenv.isLinux
          then [pkgs.htmx-lsp]
          else []
        );
    };

    startupPlugins = {
      general = with pkgs.vimPlugins; [
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
        efmls-configs-nvim
        fidget-nvim
        flash-nvim
        gitsigns-nvim
        gruvbox-nvim
        harpoon2
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
        nvim-remote-containers
        telescope-sg
        plenary-nvim
        rustaceanvim
        sg-nvim
        sniprun
        telescope-live-grep-args-nvim
        telescope-nvim
        tint-nvim
        tmux-nvim
        trouble-nvim
        undotree
        vim-be-good
        vim-dadbod
        vim-dadbod-completion
        vim-dadbod-ui
        vim-fugitive
        vim-indent-object
        vim-matchup
        vim-rhubarb
        vim-sleuth
        vim-surround
        which-key-nvim
        wilder-nvim
        zk-nvim
      ];
    };

    optionalPlugins = {
      customPlugins = with pkgs.nixCatsBuilds; [];
      gitPlugins = with pkgs.neovimPlugins; [];
      general = with pkgs.vimPlugins; [
      ];
    };

    # shared libraries to be added to LD_LIBRARY_PATH
    # variable available to nvim runtime
    sharedLibraries = {
      general = with pkgs; [
        # libgit2
      ];
    };

    environmentVariables = {
      test = {
        CATTESTVAR = "It worked!";
      };
    };

    extraWrapperArgs = {
      # https://github.com/NixOS/nixpkgs/blob/master/pkgs/build-support/setup-hooks/make-wrapper.sh
      test = [
        ''--set CATTESTVAR2 "It worked again!"''
      ];
    };

    # lists of the functions you would have passed to
    # python.withPackages or lua.withPackages

    # get the path to this python environment
    # in your lua config via
    # vim.g.python3_host_prog
    # or run from nvim terminal via :!<packagename>-python3
    extraPython3Packages = {
      python = py:
        with py; [
          cairosvg
          jupyter-client
          nbformat
          plotly
          pnglatex
          pynvim
          pyperclip
        ];
    };
    extraPythonPackages = {
      test = _: [];
    };
    # populates $LUA_PATH and $LUA_CPATH
    extraLuaPackages = {
      lua = [(l: with l; [magick])];
    };
  };

  packageDefinitions = {
    nixCats = {pkgs, ...}: {
      # they contain a settings set defined above
      # see :help nixCats.flake.outputs.settings
      settings = {
        extraName = "ncvim";
        configDirName = "ncvim";
        wrapRc = true;
        # IMPORTANT:
        # you may not alias to nvim
        # your alias may not conflict with your other packages.
        aliases = ["ncvim" "nv" "ea"];
        # caution: this option must be the same for all packages.
        nvimSRC = inputs.neovim;
      };
      # and a set of categories that you want
      # (and other information to pass to lua)
      categories = {
        general = true;
        generalBuildInputs = true;
        test = true;
        example = {
          youCan = "add more than just booleans";
          toThisSet = [
            "and the contents of this categories set"
            "will be accessible to your lua with"
            "nixCats('path.to.value')"
            "see :help nixCats"
          ];
        };
      };
    };
  };
  # In this section, the main thing you will need to do is change the default package name
  # to the name of the packageDefinitions entry you wish to use as the default.
  defaultPackageName = "nixCats";
in
  # see :help nixCats.flake.outputs.exports
  forEachSystem (system: let
    inherit (utils) baseBuilder;
    customPackager =
      baseBuilder luaPath {
        inherit system dependencyOverlays extra_pkg_config nixpkgs;
      }
      categoryDefinitions;
    nixCatsBuilder = customPackager packageDefinitions;
    # this is just for using utils such as pkgs.mkShell
    # The one used to build neovim is resolved inside the builder
    # and is passed to our categoryDefinitions and packageDefinitions
    pkgs = import nixpkgs {inherit system;};
  in {
    # this will make a package out of each of the packageDefinitions defined above
    # and set the default package to the one named here.
    packages = utils.mkPackages nixCatsBuilder packageDefinitions defaultPackageName;

    # choose your package for devShell
    # and add whatever else you want in it.
    devShells = {
      default = pkgs.mkShell {
        name = defaultPackageName;
        packages = [(nixCatsBuilder defaultPackageName)];
        inputsFrom = [];
        shellHook = ''
        '';
      };
    };

    # To choose settings and categories from the flake that calls this flake.
    # and you export overlays so people dont have to redefine stuff.
    inherit customPackager;
  })
  // {
    # these outputs will be NOT wrapped with ${system}

    # this will make an overlay out of each of the packageDefinitions defined above
    # and set the default overlay to the one named here.
    overlays =
      utils.makeOverlays luaPath {
        # we pass in the things to make a pkgs variable to build nvim with later
        inherit nixpkgs dependencyOverlays extra_pkg_config;
        # and also our categoryDefinitions
      }
      categoryDefinitions
      packageDefinitions
      defaultPackageName;

    # we also export a nixos module to allow configuration from configuration.nix
    nixosModules.default = utils.mkNixosModules {
      inherit
        defaultPackageName
        dependencyOverlays
        luaPath
        categoryDefinitions
        packageDefinitions
        nixpkgs
        ;
    };
    # and the same for home manager
    homeModule = utils.mkHomeModules {
      inherit
        defaultPackageName
        dependencyOverlays
        luaPath
        categoryDefinitions
        packageDefinitions
        nixpkgs
        ;
    };
    # now we can export some things that can be imported in other
    # flakes, WITHOUT needing to use a system variable to do it.
    # and update them into the rest of the outputs returned by the
    # eachDefaultSystem function.
    inherit utils categoryDefinitions packageDefinitions dependencyOverlays;
    inherit (utils) templates baseBuilder;
    keepLuaBuilder = utils.baseBuilder luaPath;
  }
