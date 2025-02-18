{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.mine.wslu;
in
{
  options.mine.wslu = {
    enable = lib.mkEnableOption "Enable WSL utilities.";
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      wslu
      shared-mime-info
    ];
    xdg = {
      mimeApps = {
        defaultApplications = {
          "text/html" = "wslview";
          "x-scheme-handler/http" = "wslview";
          "x-scheme-handler/https" = "wslview";
          "x-scheme-handler/about" = "wslview";
          "x-scheme-handler/unknown" = "wslview";
        };
      };
    };
    home.sessionVariables = {
      BROWSER = "wslview";
    };
  };

}
