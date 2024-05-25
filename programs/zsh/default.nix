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
  programs.starship = {
    enable = true;
  };
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
      export STARSHIP_CONFIG=~/.nixdots/dotfiles/starship.toml
      source ${pkgs.zsh-autocomplete}/share/zsh-autocomplete/zsh-autocomplete.plugin.zsh
    '';

    initExtra = ''
      # source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
      # source ${config.xdg.configHome}/zsh/.p10k.zsh
      source ${pkgs.zsh-vi-mode}/share/zsh-vi-mode/zsh-vi-mode.plugin.zsh
      source ${pkgs.zsh-you-should-use}/share/zsh/plugins/you-should-use/you-should-use.plugin.zsh
      source ${pkgs.zsh-fast-syntax-highlighting}/share/zsh/site-functions/fast-syntax-highlighting.plugin.zsh
      source ${pkgs.nix-zsh-completions}/share/zsh/plugins/nix/nix-zsh-completions.plugin.zsh

      fpath=(${pkgs.nix-zsh-completions}/share/zsh/site-functions $fpath)
      autoload -U compinit && compinit


      # zsh vi mode settings
      ZVM_VI_INSERT_ESCAPE_BINDKEY=jk
      ZVM_READKEY_ENGINE=$ZVM_READKEY_ENGINE_NEX

      set -o vi
      export PATH=$HOME/.cargo/bin:$PATH # add cargo to the front of the path so dev tools are used > sys
      export TWM_DEFAULT="default"

      export EDITOR="nv"
      export VISUAL="ncvim" # dont know what this is for tbh
      export PATH=$HOME/.pyenv/shims:$PATH

      tmux has-session -t $TWM_DEFAULT >/dev/null 2>&1 || twm -d -p . -n $TWM_DEFAULT


      # zsh-autocomplete settings
      zstyle ':autocomplete:*complete*:*' insert-unambiguous yes
      zstyle ':autocomplete:*history*:*' insert-unambiguous yes
      zstyle ':autocomplete:menu-search:*' insert-unambiguous yes
      bindkey '\t' menu-select "$terminfo[kcbt]" menu-select
      bindkey -M menuselect '\t' menu-complete "$terminfo[kcbt]" reverse-menu-complete

      export PATH=$HOME/.local/bin:$PATH
      export ZK_NOTEBOOK_DIR=$HOME/zk
    '';

    oh-my-zsh = {
      enable = true;
      plugins = [ "git" ];
    };
  };

  programs.bash.enable = true; # just in case

  programs.command-not-found.enable = false;
  programs.nix-index = {
    enable = true;
    enableZshIntegration = true;
  };

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
    ef = "nv $(find_file_up_tree flake.nix)";
  };
}
