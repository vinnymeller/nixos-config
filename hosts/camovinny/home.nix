{
  ...
}:
{
  imports = [
    ../../modules/home-manager
  ];

  profile.vinny.enable = true;
  mine.pkgs.exclude = [ "swap_audio_output" ];
  hmStandalone = true;

  home.username = "vinny";
  home.homeDirectory = "/Users/vinny";
  home.stateVersion = "22.11";

}
