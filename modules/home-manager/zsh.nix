{
  config,
  lib,
  pkgs,
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
in
{
  imports = [
    ./wslu.nix
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

    # zsh doesn't have an extraPackages option, so we have to add them to home.packages
    home.packages = with pkgs; [
      twm
      ijq
      nix-zsh-completions
      zsh-powerlevel10k
      zsh-vi-mode
      zsh-you-should-use
      zsh-fast-syntax-highlighting
      zsh-autocomplete
      zsh-completions
      (aider-chat.withOptional {
        withPlaywright = true;
        withBrowser = true;
        withBedrock = true;
      })
    ];
    programs.zsh = {
      enable = true;
      enableCompletion = false;
      autosuggestion.enable = true;
      dotDir = ".config/zsh";

      history = {
        size = 10000;
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

          source ${pkgs.zsh-fast-syntax-highlighting}/share/zsh/site-functions/fast-syntax-highlighting.plugin.zsh
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


          # zsh-autocomplete settings
          zstyle ':autocomplete:*complete*:*' insert-unambiguous yes
          zstyle ':autocomplete:*history*:*' insert-unambiguous yes
          zstyle ':autocomplete:menu-search:*' insert-unambiguous yes
          bindkey '\t' menu-select "$terminfo[kcbt]" menu-select
          bindkey -M menuselect '\t' menu-complete "$terminfo[kcbt]" reverse-menu-complete

          export PATH=$HOME/.local/bin:$HOME/.cargo/bin:$HOME/.nix-profile/bin:$PATH # make sure nix profile is in front of other stuff
          export ZK_NOTEBOOK_DIR=$HOME/zk

          # leaving this in for secrets that I may not want to manage with nix
          if [ -f ~/.config/.secrets.sh ]; then
            source ~/.config/.secrets.sh
          fi
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

    # copy our powerlevel10k config over
    home.file.".config/zsh/.p10k.zsh".source = ../../dotfiles/zsh/.p10k.zsh;
    home.file.".aider.conf.yml".source = ../../dotfiles/.aider.conf.yml;

    programs.atuin = {
      enable = true;
      enableZshIntegration = true;
    };

    programs.direnv.enable = true;
    programs.direnv.nix-direnv.enable = true;

    home.shellAliases = {
      cdots = "pushd ~/.nixdots";
      nb = "sudo nixos-rebuild --flake ~/.nixdots switch";
      nt = "sudo nixos-rebuild --flake ~/.nixdots test";
      hms = "nix run home-manager switch -- --flake ~/.nixdots";
      root = "cd $TWM_ROOT";
      etwm = "TWM_CONFIG_FILE= twm";
      ef = "nv $(find_file_up_tree flake.nix)";
      da = "direnv allow";
      dr = "direnv reload";
      nfu = "nix flake update";
    };
  };
}
