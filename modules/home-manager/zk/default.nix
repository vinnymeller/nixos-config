{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.mine.zk;
in
{
  options.mine.zk = {
    enable = mkEnableOption "Enable ZK note-taking app.";
  };
  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      zk
      fzf
    ];

    home.file.".config/zk".source = ./cfg;
  };
}
