{
  lib,
  ...
}:
{
  imports = [
    ../../modules/home-manager
  ];

  profile.vinny.enable = true;

  home.username = "vinny";
  home.homeDirectory = lib.mkForce "/home/vinny";
  home.stateVersion = "25.11";
}
