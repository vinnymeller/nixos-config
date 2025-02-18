{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.mine.pkgs;
  cust_pkgs = import ../../pkgs { inherit pkgs; };
in
{
  options.mine.pkgs = {
    enable = mkEnableOption "Include my custom packages/scripts in the environment.";
  };

  config = mkIf cfg.enable {
    home.packages = builtins.attrValues cust_pkgs;
  };
}
