{
  options =
    { lib, config, ... }:
    {
      autoStartTmux = lib.mkOption {
        type = lib.types.bool;
        default = !config.features.wsl.enable;
        description = "Automatically enter tmux when opening a new shell.";
      };
    };

  assertions =
    { features, ... }:
    [
      {
        assertion = features.zsh.autoStartTmux -> features.tmux.enable;
        message = "features.zsh.autoStartTmux requires features.tmux to be enabled.";
      }
    ];

  nixos =
    {
      cfg,
      eachUser,
      lib,
      pkgs,
      ...
    }:
    {
      programs.zsh = {
        enable = lib.mkDefault true;
        enableCompletion = lib.mkDefault false;
      };

      environment.pathsToLink = [ "/share/zsh" ];

      users.users = eachUser { shell = pkgs.zsh; };
    };

  home =
    {
      cfg,
      lib,
      pkgs,
      hmConfig,
      ...
    }:
    {
      xdg.enable = lib.mkDefault true;

      home.packages = with pkgs; [
        devenv
        find-file-up-tree
        gh-clone-all
        worktree-helper
        build-nix-pkg-update
        twm
        jq
        ijq
        lsof
        yj
        ripgrep
        lazygit
        watchexec
        yazi
        dua
        bat
        broot
        nh
        duf
        eza
        fd
        nix-zsh-completions
        zsh-powerlevel10k
        zsh-vi-mode
        zsh-you-should-use
        zsh-fast-syntax-highlighting
        zsh-autocomplete
        zsh-completions
        claude-code
        llm-agents.codex
        neovim
      ];

      programs.zsh = {
        enable = lib.mkDefault true;
        enableCompletion = lib.mkDefault false;
        autosuggestion.enable = lib.mkDefault true;
        dotDir = "${hmConfig.xdg.configHome}/zsh";

        history = {
          size = lib.mkDefault 100000;
          path = "${hmConfig.xdg.dataHome}/zsh/history";
        };

        initContent = lib.mkBefore (
          ''
            export LC_ALL="en_US.UTF-8"
            export LANG="en_US.UTF-8"
            # NOTE: anything that requires input has to go above this!
            # Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
            # Initialization code that may require console input (password prompts, [y/n]
            # confirmations, etc.) must go above this block; everything else may go below.
            if [[ -r "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh" ]]; then
              source "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh"
            fi

            source ${pkgs.zsh-fast-syntax-highlighting}/share/zsh/plugins/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh
            source ${pkgs.zsh-autocomplete}/share/zsh-autocomplete/zsh-autocomplete.plugin.zsh

            source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
            # source ${hmConfig.xdg.configHome}/zsh/.p10k.zsh
            source ${./.p10k.zsh}
            source ${pkgs.zsh-vi-mode}/share/zsh-vi-mode/zsh-vi-mode.plugin.zsh
            source ${pkgs.zsh-you-should-use}/share/zsh/plugins/you-should-use/you-should-use.plugin.zsh
            source ${pkgs.nix-zsh-completions}/share/zsh/plugins/nix/nix-zsh-completions.plugin.zsh


            fpath=(${pkgs.zsh-completions}/share/zsh/site-functions $fpath)

            fpath=(${pkgs.nix-zsh-completions}/share/zsh/site-functions $fpath)
            autoload -U compinit && compinit


            # zsh vi mode settings
            ZVM_VI_INSERT_ESCAPE_BINDKEY=jk
            ZVM_READKEY_ENGINE=$ZVM_READKEY_ENGINE_NEX

            set -o vi
            export TWM_DEFAULT="default"

            export EDITOR="nv"
            export VISUAL="nv" # dont know what this is for tbh

            # let nvim handle wrapping
            export MANWIDTH=999

            export MANPAGER="nv +Man!"


            # zsh-autocomplete settings
            zstyle ':autocomplete:*complete*:*' insert-unambiguous yes
            zstyle ':autocomplete:*history*:*' insert-unambiguous yes
            zstyle ':autocomplete:menu-search:*' insert-unambiguous yes
            bindkey '\t' menu-select "$terminfo[kcbt]" menu-select
            bindkey -M menuselect '\t' menu-complete "$terminfo[kcbt]" reverse-menu-complete

            export PATH=$HOME/.local/bin:$HOME/.cargo/bin:$PATH # make sure nix profile is in front of other stuff
            export ZK_NOTEBOOK_DIR=$HOME/dev/vinnymeller/zk
          ''
          + (
            if cfg.autoStartTmux then
              ''
                # create a default tmux session if it doesnt exist
                tmux has-session -t $TWM_DEFAULT >/dev/null 2>&1 || twm -d -p $HOME -n $TWM_DEFAULT

                # if we aren't currently in tmux, we will attach to something
                if [ -z "$TMUX" ]; then
                  # if there are no clients on the default session, attach to it
                  if [ $(tmux list-clients -t $TWM_DEFAULT | wc -l) -eq 0 ]; then
                    tmux attach-session -t $TWM_DEFAULT
                  # otherwise, attach to a session grouped with the default session
                  else
                    tmux attach-session -t $(twm -d -N -g -G $TWM_DEFAULT)
                  fi
                fi
              ''
            else
              ""
          )
        );

        oh-my-zsh = {
          enable = lib.mkDefault true;
          plugins = [ "git" ];
        };
      };

      programs.bash.enable = lib.mkDefault true;
      programs.zoxide = {
        enable = lib.mkDefault true;
        enableZshIntegration = lib.mkDefault true;
      };

      home.file.".config/twm".source = ./twm;

      programs.direnv.enable = lib.mkDefault true;
      programs.direnv.nix-direnv.enable = lib.mkDefault true;

      home.shellAliases = {
        cdots = lib.mkDefault "pushd ~/.nixdots";
        nb = lib.mkDefault "nh os switch -j 4 --cores 8 ~/.nixdots";
        hms = lib.mkDefault "nh home switch -j 4 --cores 4 ~/.nixdots";
        root = lib.mkDefault "cd $TWM_ROOT";
        etwm = lib.mkDefault "TWM_CONFIG_FILE= twm";
        ef = lib.mkDefault "nv $(find-file-up-tree flake.nix)";
        da = lib.mkDefault "direnv allow";
        dr = lib.mkDefault "direnv reload";
        nfu = lib.mkDefault "nix flake update";
        nru = lib.mkDefault "NIXPKGS_ALLOW_UNFREE=1 nix run --impure";
        nsu = lib.mkDefault "NIXPKGS_ALLOW_UNFREE=1 nix shell --impure";
        nbu = lib.mkDefault "NIXPKGS_ALLOW_UNFREE=1 nix build --impure";
        path = lib.mkDefault "path() { realpath $(which $1); }; path";
        lg = lib.mkDefault "lazygit";
      };
    };
}
