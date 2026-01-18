{
  config,
  lib,
  pkgs,
  inputs,
  myUtils,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;
  cfg = config.mine.zsh;
  std = inputs.nix-std.lib;
  mcpConfig = import ./mcpConfig.nix { inherit pkgs; };
  claudeMcpConfig = {
    mcpServers = mcpConfig;
  };
  codexMcpConfig = {
    mcp_servers = mcpConfig;
  };
in
{
  imports = [
    ../wslu.nix
  ];

  options.mine.zsh = {
    enable = mkEnableOption "Enable Zsh.";
    autoStartTmux = mkOption {
      type = types.bool;
      default = !config.mine.wslu.enable;
      description = ''
        Automatically enter tmux when opening a new shell.
      '';
    };
  };
  config = mkIf cfg.enable {

    xdg.enable = true;

    # zsh doesn't have an extraPackages option, so we have to add them to home.packages
    home.packages =
      with pkgs;
      [
        devenv
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
      ]
      ++ [
        (inputs.wrappers.wrappedModules.claude-code.wrap {
          inherit pkgs;
          package = pkgs.llm-agents.claude-code;
          extraPackages = with pkgs; [
            nodejs_24
            uv
            bun
            python3
            libnotify
            jq
            bash
          ];
          strictMcpConfig = false;
        })
      ];
    programs.zsh = {
      enable = true;
      enableCompletion = false;
      autosuggestion.enable = true;
      dotDir = "${config.xdg.configHome}/zsh";

      history = {
        size = 100000;
        path = "${config.xdg.dataHome}/zsh/history";
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
          source ${config.xdg.configHome}/zsh/.p10k.zsh
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
          export TWM_CONFIG_FILE="$HOME/.nixdots/dotfiles/twm/twm.yaml"

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
        enable = true;
        plugins = [ "git" ];
      };
    };

    programs.bash.enable = true; # just in case
    programs.zoxide = {
      enable = true;
      enableZshIntegration = true;
    };

    home.file.".config/zsh/.p10k.zsh".source = ../../../dotfiles/zsh/.p10k.zsh;
    home.file.".claude/CLAUDE.md".source = ../../../dotfiles/claude/CLAUDE.md;
    home.file.".claude/anthropic_key.sh" = {
      text = "echo $ANTHROPIC_API_KEY";
      executable = true;
    };

    home.activation =
      let
        claudeMcpFile = pkgs.writeTextFile {
          name = "claude-mcp.json";
          text = (std.serde.toJSON claudeMcpConfig);
        };
        codexMcpFile = pkgs.writeTextFile {
          name = "codex-mcp.json";
          text = (std.serde.toJSON codexMcpConfig);
        };
      in
      {
        mergeClaudeDotJson = myUtils.mergeJsonTopLevel {
          pkgs = pkgs;
          mergeInto = "${config.home.homeDirectory}/.claude.json";
          mergeFrom = claudeMcpFile;
        };
        mergeGeminiDotJson = myUtils.mergeJsonTopLevel {
          pkgs = pkgs;
          mergeInto = "${config.home.homeDirectory}/.gemini/settings.json";
          mergeFrom = claudeMcpFile;
        };
        mergeCodexDotToml = myUtils.mergeIntoTomlFromJsonTopLevel {
          pkgs = pkgs;
          mergeInto = "${config.home.homeDirectory}/.codex/config.toml";
          mergeFrom = codexMcpFile;
        };
        mergeClaudeSettings = myUtils.mergeJsonDeep {
          pkgs = pkgs;
          mergeInto = "${config.home.homeDirectory}/.claude/settings.json";
          mergeFrom = "${../../../dotfiles/claude/settings.json}";
        };
      };

    programs.direnv.enable = true;
    programs.direnv.nix-direnv.enable = true;

    home.shellAliases = {
      cdots = "pushd ~/.nixdots";
      # nb = "sudo nixos-rebuild --flake ~/.nixdots switch";
      nb = "nh os switch ~/.nixdots";
      # nt = "sudo nixos-rebuild --flake ~/.nixdots test";
      nt = "nh os test ~/.nixdots";
      # hms = "nix run home-manager switch -- --flake ~/.nixdots";
      hms = "nh home switch ~/.nixdots";
      root = "cd $TWM_ROOT";
      etwm = "TWM_CONFIG_FILE= twm";
      ef = "nv $(find-file-up-tree flake.nix)";
      da = "direnv allow";
      dr = "direnv reload";
      nfu = "nix flake update";
      nru = "NIXPKGS_ALLOW_UNFREE=1 nix run --impure";
      nsu = "NIXPKGS_ALLOW_UNFREE=1 nix shell --impure";
      nbu = "NIXPKGS_ALLOW_UNFREE=1 nix build --impure";
      path = "path() { realpath $(which $1); }; path";
      lg = "lazygit";
    };
  };
}
