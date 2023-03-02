{ config, pkgs, ...}:

{
  # Let home-manager manage itself
  programs.home-manager.enable = true;

  home.username = "vinny";
  home.homeDirectory = "/home/vinny";

  home.stateVersion = "22.11";

  home.packages = with pkgs; [
    # alacritty
    gcc
    firefox
    neovim
    htop
    libvirt
    nodejs-19_x
    dmenu
    nerdfonts
    neofetch
    qemu
    ripgrep
    rustup
    unzip
    virt-manager
    yubioath-flutter
    zsh-powerlevel10k
  ];

  programs.git = {
    enable = true;
    userName = "Vinny Meller";
    userEmail = "vinnymeller@gmail.com";
  };

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    dotDir = ".config/zsh";
    shellAliases = {
      l = "ls -la";
      nvim = "nvim -u ~/.nixdots/users/vinny/config/nvim/init.lua";
    };

    sessionVariables = {
        EDITOR = "nvim";
    };

    history = {
      size = 10000;
      path = "${config.xdg.dataHome}/zsh/history";
    };

    initExtra = "source ${config.xdg.configHome}/zsh/.p10k.zsh\n";

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

  programs.kitty = {
    enable = true;
    font = {
      name = "Jetbrains Mono";
      package = pkgs.jetbrains-mono;
    };
    extraConfig = "background_opacity	0.85";
  };

  home.file = {
    # ".config/nvim".source = ./config/nvim;
    ".config/zsh/.p10k.zsh".source = ./config/zsh/.p10k.zsh;
  };
}
