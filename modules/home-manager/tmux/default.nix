{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf mkForce;
  cfg = config.mine.tmux;
in
{
  options.mine.tmux = {
    enable = mkEnableOption "Enable tmux.";
  };

  config = mkIf cfg.enable {
    programs.tmux.enable = true;
    programs.tmux.extraConfig = builtins.readFile ./.tmux.conf;
    home.sessionVariables = {
      TMUX_TMPDIR = mkForce "/tmp";
    };
  };
}
