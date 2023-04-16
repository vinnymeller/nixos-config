{ config, pkgs, ... }: {

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    dotDir = ".config/zsh";

    history = {
      size = 10000;
      path = "${config.xdg.dataHome}/zsh/history";
    };

    initExtra = ''
    source ${config.xdg.configHome}/zsh/.p10k.zsh
    eval "$(direnv hook zsh)"
    export PATH=$PATH:/$HOME/.nix-profile/bin
    export TWM_DEFAULT="default"

    tmux has-session -t $TWM_DEFAULT >/dev/null 2>&1 || tmux new -ds $TWM_DEFAULT
    '';

    oh-my-zsh = {
      enable = true;
      plugins = [ "git" ];
    };
    plugins = [
      {
        name = "zsh-autosuggestions";
	src = pkgs.fetchFromGitHub {
	  owner = "zsh-users";
	  repo = "zsh-autosuggestions";
	  rev = "v0.7.0";
	  sha256 = "KLUYpUu4DHRumQZ3w59m9aTW6TBKMCXl2UcKi4uMd7w=";
	};
      }
      {
        name = "zsh-syntax-highlighting";
	src = pkgs.fetchFromGitHub {
	  owner = "zsh-users";
	  repo = "zsh-syntax-highlighting";
	  rev = "0.7.1";
	  sha256 = "gOG0NLlaJfotJfs+SUhGgLTNOnGLjoqnUp54V9aFJg8=";
	};
      }
      {
        name = "powerlevel10k";
	src = pkgs.zsh-powerlevel10k;
	file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
      }
    ];
  };

  programs.bash.enable = true; # just in case

  # copy our powerlevel10k config over
  home.file.".config/zsh/.p10k.zsh".source = ../../dotfiles/zsh/.p10k.zsh;

  home.shellAliases = {
    cdots = "pushd ~/.nixdots";
    nb = "sudo nixos-rebuild --flake ~/.nixdots switch";
    hms = "nix run ~/.nixdots switch -- --flake ~/.nixdots";
  };
}
