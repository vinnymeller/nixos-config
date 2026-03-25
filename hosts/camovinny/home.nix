{
  pkgs,
  ...
}:
{
  imports = [
    ../../modules/home-manager
  ];

  features.defaults.users = [ "vinny" ];
  features.git.enable = true;
  features.gpg.enable = true;
  features.nix.enable = true;
  features.ssh.enable = true;
  features.tmux.enable = true;
  features.zsh.enable = true;
  home.stateVersion = "25.11";

  home.packages = with pkgs; [
    awscli2
    ijq
    jq
    sqlfluff
    nodejs
    (pre-commit.override { dotnet-sdk = pkgs.stable-pkgs.dotnet-sdk; })
    uv
    (dbt.withAdapters (a: [ a.dbt-snowflake ]))
  ];

}
