{
  pkgs,
  config,
  lib,
  outputs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf mkDefault;
  cfg = config.mine.nix;
in
{
  options.mine.nix = {
    enable = mkEnableOption "Enable Nix package manager.";
  };

  config = mkIf cfg.enable {
    nix = {
      package = mkDefault pkgs.nixVersions.git;
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
