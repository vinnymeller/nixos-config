{
  ...
}:
{
  imports = [
    ../../modules/home-manager
  ];

  profile.vinny.enable = true;
  mine.pkgs.exclude = [ "swap-audio-output" ];
  hmStandalone = true;

  home.username = "vinny";
  home.homeDirectory = "/Users/vinny";
  home.stateVersion = "22.11";

}
