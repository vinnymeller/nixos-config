{
  pkgs,
  config,
  lib,
  outputs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.mine.nix;
in
{
  options.mine.nix = {
    enable = mkEnableOption "Enable Nix package manager.";
  };

  config = mkIf cfg.enable {
    nixpkgs = {
      overlays = builtins.attrValues outputs.overlays;
      config = {
        allowUnfree = true;
        allowUnsupportedSystem = true;
      };
    };
    nix = {
      package = pkgs.nixVersions.git;
      settings = {
        experimental-features = [
          "nix-command"
          "flakes"
        ];
        require-sigs = true;
        auto-optimise-store = true;
        trusted-users = [
          "vinny" # TODO: probably want to make this a variable like ${homeUser} with extraSpecialArgs
          "root"
        ];
      };
    };
  };

}
