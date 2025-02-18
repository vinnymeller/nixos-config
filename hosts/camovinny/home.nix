{
  ...
}:
{
  imports = [
    ../../modules/home-manager
  ];

  profile.vinny.enable = true;
  hmStandalone = true;

  home.username = "vinny";
  home.homeDirectory = "/Users/vinny";
  home.stateVersion = "22.11";

}
