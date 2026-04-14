{
  ...
}:
{
  imports = [
    ../../modules/home-manager
  ];

  features.defaults.users = [ "vinny" ];
  features.git.enable = true;
  features.nix.enable = true;
  features.ssh.enable = true;
  features.tmux.enable = true;
  features.zsh.enable = true;
  home.stateVersion = "25.11";
}
