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
        wsl-open
        shared-mime-info
      ];

      xdg.mimeApps.defaultApplications = {
        "text/html" = "wsl-open";
        "x-scheme-handler/http" = "wsl-open";
        "x-scheme-handler/https" = "wsl-open";
        "x-scheme-handler/about" = "wsl-open";
        "x-scheme-handler/unknown" = "wsl-open";
      };

      home.sessionVariables = {
        BROWSER = "wsl-open";
      };
    };
}
