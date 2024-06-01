{
  config,
  pkgs,
  services,
  ...
}:
{
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
      sessionCommands = ''
        ~/.nixdots/dotfiles/xrandr_layout.sh
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
    videoDrivers = [ "nvidia" ];
  };

  services.picom = {
    enable = true;
    backend = "glx";
    fade = true;
    fadeDelta = 5;
    opacityRules = [ "100:QTILE_INTERNAL:32c" ];
    shadow = true;
    shadowOpacity = 0.5;
  };
}
