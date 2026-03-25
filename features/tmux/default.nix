{
  home =
    {
      cfg,
      lib,
      pkgs,
      ...
    }:
    {
      programs.tmux = {
        enable = lib.mkDefault true;
        extraConfig = builtins.readFile ./.tmux.conf;
      };
      home.sessionVariables = {
        TMUX_TMPDIR = lib.mkForce "/tmp";
      };
      home.packages = [ pkgs.tmux-kill-and-attach ];
    };
}
