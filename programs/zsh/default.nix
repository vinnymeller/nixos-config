{ config, pkgs, ... }:
{
  # zsh doesn't have an extraPackages option, so we have to add them to home.packages
  home.packages = with pkgs; [
    twm
    nix-zsh-completions
    zsh-powerlevel10k
    zsh-vi-mode
    zsh-you-should-use
    zsh-fast-syntax-highlighting
    zsh-autocomplete
    zsh-completions
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

    initExtraFirst = ''
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
    '';

    initExtra = ''
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
      export PATH=$HOME/.cargo/bin:$PATH # add cargo to the front of the path so dev tools are used > sys
      export PATH=$PATH:/$HOME/.nix-profile/bin
      export TWM_DEFAULT="default"
      export TWM_CONFIG_FILE="$HOME/.nixdots/dotfiles/twm/twm.yaml"

      export EDITOR="nv"
      export VISUAL="nv" # dont know what this is for tbh

      tmux has-session -t $TWM_DEFAULT >/dev/null 2>&1 || twm -d -p . -n $TWM_DEFAULT


      # zsh-autocomplete settings
      zstyle ':autocomplete:*complete*:*' insert-unambiguous yes
      zstyle ':autocomplete:*history*:*' insert-unambiguous yes
      zstyle ':autocomplete:menu-search:*' insert-unambiguous yes
      bindkey '\t' menu-select "$terminfo[kcbt]" menu-select
      bindkey -M menuselect '\t' menu-complete "$terminfo[kcbt]" reverse-menu-complete

      export PATH=$HOME/.local/bin:$PATH
      export ZK_NOTEBOOK_DIR=$HOME/zk

      if [ -f ~/.config/.secrets.sh ]; then
        source ~/.config/.secrets.sh
      fi
    '';

    oh-my-zsh = {
      enable = true;
      plugins = [ "git" ];
    };
  };

  programs.bash.enable = true; # just in case

  # copy our powerlevel10k config over
  home.file.".config/zsh/.p10k.zsh".source = ../../dotfiles/zsh/.p10k.zsh;

  programs.atuin = {
    enable = true;
    enableZshIntegration = true;
  };

  home.shellAliases = {
    cdots = "pushd ~/.nixdots";
    nb = "sudo nixos-rebuild --flake ~/.nixdots switch";
    nt = "sudo nixos-rebuild --flake ~/.nixdots test";
    hms = "nix run home-manager switch -- --flake ~/.nixdots";
    root = "cd $TWM_ROOT";
    etwm = "TWM_CONFIG_FILE= twm";
    ef = "nv $(find_file_up_tree flake.nix)";
  };
}
