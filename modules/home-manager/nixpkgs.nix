{
  config,
  lib,
  outputs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.mine.nixpkgs;
in
{
  options.mine.nixpkgs = {
    enable = mkEnableOption "Enable Nixpkgs configuration.";
  };

  config = mkIf cfg.enable {
    nixpkgs = {
      overlays = builtins.attrValues outputs.overlays;
      config = {
        allowUnfree = true;
        allowUnsupportedSystem = true;
      };
    };
  };

}
