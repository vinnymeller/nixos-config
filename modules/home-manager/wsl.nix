{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf mkForce;
  cfg = config.mine.wsl;
in
{
  imports = [
    ./git.nix
    ./wslu.nix
    ./zsh.nix
  ];

  options.mine.wsl = {
    enable = mkEnableOption "Enable WSL-specific configuration options.";
  };

  config = mkIf cfg.enable {
    mine.git.gpgSignDefault = mkForce false;
    mine.wslu.enable = mkForce true;
    mine.zsh.autoStartTmux = mkForce false;
  };

}
