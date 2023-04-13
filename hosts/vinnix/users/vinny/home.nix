{ config, pkgs, ...}:
let
    cust_pkgs = import ../../../../pkgs { inherit pkgs; };
in
{

  imports = [
    ../../../../modules/git
    ../../../../modules/zsh
    ../../../../modules/neovim
    ../../../../modules/kitty
    ../../../../modules/ranger
    ../../../../modules/tmux
  ];
  # Let home-manager manage itself
  programs.home-manager.enable = true;

  # direnv !
  programs.direnv.enable = true;
  programs.direnv.nix-direnv.enable = true;


  home.username = "vinny";
  home.homeDirectory = "/home/vinny";

  home.stateVersion = "22.11";

  home.packages = with pkgs; [
    gcc
    firefox
    htop
    libvirt
    dmenu
    discord
    dunst
    feh
    lxde.lxsession
    nerdfonts
    neofetch
    obs-studio
    osu-lazer
    qemu
    man-pages # linux man pages, goes with tlpi
    pkg-config
    protonup-qt
    rustup
    unzip
    virt-manager
    yubioath-flutter
    rofi
    spotify
    zsh-powerlevel10k
  ] ++ builtins.attrValues cust_pkgs;

  home.file.".config/qtile".source = ../../../../dotfiles/qtile;
}
