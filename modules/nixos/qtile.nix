{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkOption
    mkIf
    types
    ;
  cfg = config.mine.dm.qtile;
in
{
  options.mine.dm.qtile = {
    enable = mkEnableOption "Enable qtile";
    initialSessionCommands = mkOption {
      type = types.str;
      default = ''
        ~/.nixdots/dotfiles/xrandr_layout.sh
      '';
      description = "Extra commands to add to the beginning of sessionCommands";
    };
    videoDrivers = mkOption {
      type = types.listOf types.str;
      default = [ "nvidia" ];
      description = "List of video drivers";
    };
  };
  config = mkIf cfg.enable {
    environment.variables = {
      GDK_SCALE = "2";
      GDK_DPI_SCALE = "0.5";
      _JAVA_OPTIONS = "-Dsun.java2d.uiScale=2";
    };

    services.xserver = {
      enable = true;
      autorun = true;
      autoRepeatDelay = 200;
      autoRepeatInterval = 20;
      upscaleDefaultCursor = true;
      dpi = 130;
      displayManager = {
        gdm.enable = true;
        sessionCommands =
          cfg.initialSessionCommands
          + ''
            xset dpms 0 0 0 && xset s noblank && xset s off
            lxsession -s qtile -e qtile &
            feh --bg-fill ~/.nixdots/files/avatar-wallpaper.png
          '';
      };
      windowManager.qtile = {
        enable = true;
        package = pkgs.qtile-unwrapped;
      };
      windowManager.session = [
        {
          name = "qtile";
          start = ''
            ${pkgs.qtile-unwrapped}/bin/qtile start -b x11 \
            --config /home/vinny/.config/qtile/config.py &
            waitPID=$!
          '';
        }
      ];
      xkb.layout = "us";
      videoDrivers = cfg.videoDrivers;
    };

    services.picom = {
      enable = true;
      backend = "glx";
      fade = false;
      fadeDelta = 5;
      opacityRules = [ "100:QTILE_INTERNAL:32c" ];
      shadow = true;
      shadowOpacity = 0.5;
    };
  };

}
