{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.mine.ssh;
in
{
  options.mine.ssh = {
    enable = mkEnableOption "Enable SSH";
  };

  config = mkIf cfg.enable {
    programs.ssh = {
      enable = true;
      matchBlocks = {
        "github.com" = {
          hostname = "ssh.github.com";
          port = 443;
          user = "git";
        };
      };
    };
  };

}
