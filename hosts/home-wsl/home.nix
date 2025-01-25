{
  lib,
  ...
}:
{
  imports = [
    ../../hm
  ];

  profile.vinny.enable = true;
  profile.vinny.wsl = true;

  home.username = "vinny";
  home.homeDirectory = lib.mkForce "/home/vinny";
  home.stateVersion = "24.05";
}
