{ pkgs, ... }:
{
  home.packages = with pkgs; [
    zk
    fzf
  ];

  home.file.".config/zk".source = ../../dotfiles/zk;
}
