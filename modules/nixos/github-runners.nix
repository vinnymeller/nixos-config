{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.mine.services.github-runners;
in
{

  imports = [
    # think this is bad practice but fuck it
    inputs.github-nix-ci.nixosModules.default
  ];

  options.mine.services.github-runners = {
    enable = mkEnableOption "Enable GitHub Actions self-hosted runners.";
  };

  config = mkIf cfg.enable {

    services.github-nix-ci = {
      age.secretsDir = ../../secrets;
      runnerSettings = {
        extraLabels = [ "nix" ];
        extraPackages = with pkgs; [
          openssl # needed for nicknovitski/nix-develop
          git-lfs # needed for lfs flag
          gh
          docker
        ];
      };
      orgRunners = {
        "mxves".num = 2;
      };
    };

    virtualisation.docker.enable = true;

    users.users.github-runner = {
      extraGroups = [ "docker" ];
    };
  };
}
