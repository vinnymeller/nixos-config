{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;
  cfg = config.mine.pkgs;
  cust_pkgs = import ../../pkgs { inherit pkgs; };
in
{
  options.mine.pkgs = {
    enable = mkEnableOption "Include my custom packages/scripts in the environment.";
    exclude = mkOption {
      type = types.listOf types.str;
      default = [ ];
    };
  };

  config = mkIf cfg.enable {
    home.packages = builtins.attrValues (
      lib.filterAttrs (name: _value: !lib.elem name cfg.exclude) cust_pkgs
    );
    # home.packages = builtins.attrValues cust_pkgs;
  };
}
