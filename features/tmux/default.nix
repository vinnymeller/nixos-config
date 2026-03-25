{
  home =
    { cfg, lib, ... }:
    {
      programs.tmux = {
        enable = lib.mkDefault true;
        extraConfig = builtins.readFile ./.tmux.conf;
      };
      home.sessionVariables = {
        TMUX_TMPDIR = lib.mkForce "/tmp";
      };
    };
}
