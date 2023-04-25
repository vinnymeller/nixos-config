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
    discord
    dmenu
    dunst
    feh
    firefox
    gcc
    htop
    libvirt
    lxde.lxsession
    man-pages # linux man pages, goes with tlpi
    neofetch
    nerdfonts
    obs-studio
    osu-lazer
    pavucontrol
    pkg-config
    protonup-qt
    qemu
    rofi
    rustup
    screenkey
    spotify
    twm
    unzip
    virt-manager
    yubioath-flutter
    zsh-powerlevel10k
  ] ++ builtins.attrValues cust_pkgs;

  home.file.".config/qtile".source = ../../../../dotfiles/qtile;
}
