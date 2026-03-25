{
  home =
    {
      cfg,
      lib,
      pkgs,
      ...
    }:
    {
      home.packages = with pkgs; [
        zk
        fzf
      ];

      home.file.".config/zk".source = ./cfg;
    };
}
