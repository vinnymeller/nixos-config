{ config, pkgs, ... }:
{

  home.packages = with pkgs; [ ranger ];

  home.shellAliases = {
    ranger = "ranger --confdir=${config.home.homeDirectory}/.nixdots/dotfiles/ranger"; # have to do this because ranger requires the config dir to be writable
  };
}
