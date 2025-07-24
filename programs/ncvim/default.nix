{ inputs, ... }@attrs:
let
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
  dependencyOverlays = (import ./overlays inputs) ++ [
    (utils.standardPluginOverlay inputs)
    (final: prev: {
      blink-cmp-flake = inputs.blink-cmp.packages.${final.system}.default;
    })
  ];

  categoryDefinitions =
    {
      pkgs,
      settings,
      categories,
      name,
      ...
    }@packageDef:
    let
      custom-vim-plugins = pkgs.vimPlugins.extend (
        pkgs.callPackage ../../pkgs/vim-plugins.nix {
          inherit (pkgs.vimUtils) buildVimPlugin;
          inherit (pkgs.neovimUtils) buildNeovimPlugin;
        }
      );
    in
    {
      propagatedBuildInputs = {
        generalBuildInputs = with pkgs; [ ];
      };

      lspsAndRuntimeDeps = {
        general =
          with pkgs;
          [
            ast-grep
            black
            cargo
            ccls
            chafa
            dockerfile-language-server-nodejs
            efm-langserver
            fd
            fzf
            gcc
            git
            gopls
            haskellPackages.haskell-language-server
            imagemagick
            isort
            ltex-ls-plus
            lua-language-server
            luajitPackages.jsregexp

            # nixd uses nixpkgs-fmt
            nixd
            nixpkgs-fmt
            nixfmt-rfc-style

            # nodePackages.eslint
            nodePackages.sql-formatter
            nodePackages.typescript-language-server
            nodejs
            #ocamlPackages.ocaml-lsp
            postgresql
            prettierd
            basedpyright
            ripgrep
            bat
            delta
            bat
            fd
            # rust-analyzer  # provice my own rust-analyzer in a project since it sometimes causes issues having incompatible versions
            # rustfmt  # same as above
            shellcheck
            shfmt
            src-cli
            stylua
            tailwindcss-language-server
            taplo
            terraform-ls
            tree-sitter
            vscode-langservers-extracted
            xsel
            yaml-language-server
            xdg-utils
            zk
          ]
          ++ (if stdenv.isLinux then [ pkgs.htmx-lsp ] else [ ]);
      };

      startupPlugins = {
        general = with pkgs.vimPlugins; [
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
          inputs.avante-nvim.packages.${pkgs.system}.default
          leetcode-nvim
          lspkind-nvim
          ltex_extra-nvim # goes with ltex-ls providing code action functionality for nvim (e.g. add to dict, ignore rule, etc)
          lualine-nvim
          luasnip
          markdown-preview-nvim
          nui-nvim
          nvim-autopairs
          nvim-lspconfig
          nvim-treesitter-context
          nvim-treesitter-textobjects
          nvim-treesitter.withAllGrammars
          nvim-ts-autotag
          nvim-various-textobjs
          nvim-web-devicons
          oil-nvim
          pkgs.blink-cmp-flake
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
      };

      optionalPlugins = {
        customPlugins = with pkgs.nixCatsBuilds; [ ];
        gitPlugins = with pkgs.neovimPlugins; [ ];
        general = with pkgs.vimPlugins; [ ];
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
        test = [ ''--set CATTESTVAR2 "It worked again!"'' ];
      };

      python3.libraries = {
        python = py: with py; [ ];
      };

      # populates $LUA_PATH and $LUA_CPATH
      extraLuaPackages = {
        lua = [ (l: with l; [ magick ]) ];
      };
    };

  packageDefinitions = {
    nixCats =
      { pkgs, ... }:
      {
        # they contain a settings set defined above
        # see :help nixCats.flake.outputs.settings
        settings = {
          extraName = "ncvim";
          configDirName = "ncvim";
          wrapRc = true;
          # IMPORTANT:
          # you may not alias to nvim
          # your alias may not conflict with your other packages.
          aliases = [
            "ncvim"
            "nv"
            "ea"
          ];
          # caution: this option must be the same for all packages.
          # TODO: when plugins are more stable enable this to get back on nightly
          neovim-unwrapped = inputs.neovim-nightly-overlay.packages.${pkgs.system}.neovim;
          suffix-path = true;
          hosts = {
            python3 = {
              enable = true;
            };
          };
        };
        # and a set of categories that you want
        # (and other information to pass to lua)
        categories = {
          general = true;
          generalBuildInputs = true;
          test = true;
          python = true;
          lua = true;
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
forEachSystem (
  system:
  let
    inherit (utils) baseBuilder;
    customPackager = baseBuilder luaPath {
      inherit
        system
        dependencyOverlays
        extra_pkg_config
        nixpkgs
        ;
    } categoryDefinitions;
    nixCatsBuilder = customPackager packageDefinitions;
    # this is just for using utils such as pkgs.mkShell
    # The one used to build neovim is resolved inside the builder
    # and is passed to our categoryDefinitions and packageDefinitions
    pkgs = import nixpkgs { inherit system; };
  in
  {
    # this will make a package out of each of the packageDefinitions defined above
    # and set the default package to the one named here.
    packages = utils.mkPackages nixCatsBuilder packageDefinitions defaultPackageName;

    # choose your package for devShell
    # and add whatever else you want in it.
    devShells = {
      default = pkgs.mkShell {
        name = defaultPackageName;
        packages = [ (nixCatsBuilder defaultPackageName) ];
        inputsFrom = [ ];
        shellHook = '''';
      };
    };

    # To choose settings and categories from the flake that calls this flake.
    # and you export overlays so people dont have to redefine stuff.
    inherit customPackager;
  }
)
// {
  # these outputs will be NOT wrapped with ${system}

  # this will make an overlay out of each of the packageDefinitions defined above
  # and set the default overlay to the one named here.
  overlays = utils.makeOverlays luaPath {
    # we pass in the things to make a pkgs variable to build nvim with later
    inherit nixpkgs dependencyOverlays extra_pkg_config;
    # and also our categoryDefinitions
  } categoryDefinitions packageDefinitions defaultPackageName;

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
  inherit
    utils
    categoryDefinitions
    packageDefinitions
    dependencyOverlays
    ;
  inherit (utils) templates baseBuilder;
  keepLuaBuilder = utils.baseBuilder luaPath;
}
