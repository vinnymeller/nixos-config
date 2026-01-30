{
  pkgs,
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

  home.packages = with pkgs; [
    awscli2
    ijq
    jq
    sqlfluff
    nodejs_22
    (pre-commit.override { dotnet-sdk = pkgs.stable-pkgs.dotnet-sdk; })
    uv
    (dbt.withAdapters (a: [ a.dbt-snowflake ]))
  ];

}
