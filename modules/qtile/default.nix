{ config, pkgs, services, ... }: {

  services.xserver = {
    enable = true;
    autorun = true;
    autoRepeatDelay = 200;
    autoRepeatInterval = 50;
    upscaleDefaultCursor = false;
    displayManager = {
      gdm.enable = true;
      sessionCommands = ''
        ~/.nixdots/dotfiles/xrandr_layout.sh
        xset dpms 0 0 0 && xset s noblank && xset s off
        lxsession -s qtile -e qtile &
        feh --bg-fill ~/Downloads/wp7009163-avatar-appa-wallpapers.png
      '';
    };
    windowManager.qtile = {
      enable = true;
      package = pkgs.stable-pkgs.qtile-unwrapped;
    };
    windowManager.session = [{
      name = "qtile";
      start = ''
        ${pkgs.stable-pkgs.qtile-unwrapped}/bin/qtile start -b x11 \
        --config /home/vinny/.config/qtile/config.py &
        waitPID=$!
      '';
    }];
    layout = "us";
    videoDrivers = [ "nvidia" ];
  };

  services.picom = {
    enable = true;
    backend = "glx";
    fade = true;
    fadeDelta = 5;
    opacityRules = [
      "100:QTILE_INTERNAL:32c"
    ];
    shadow = true;
    shadowOpacity = 0.5;
  };
}
