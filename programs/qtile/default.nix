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
      package = pkgs.qtile-unwrapped;
    };
    windowManager.session = [{
      name = "qtile";
      start = ''
        ${pkgs.qtile-unwrapped}/bin/qtile start -b x11 \
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
    opacityRules = [ "100:QTILE_INTERNAL:32c" ];
    shadow = true;
    shadowOpacity = 0.5;
  };

  systemd.tmpfiles.rules = [
    "L+ /run/gdm/.config/monitors.xml - - - - ${
      pkgs.writeText "gdm-monitors.xml"
      /* xml */ ''

        <!-- this should all be copied from your ~/.config/monitors.xml -->
        <monitors version="2">
          <configuration>
            <logicalmonitor>
              <x>0</x>
              <y>909</y>
              <scale>0.75</scale>
              <primary>yes</primary>
              <monitor>
                <monitorspec>
                  <connector>DP-2</connector>
                </monitorspec>
                <mode>
                  <width>7680</width>
                  <height>2160</height>
                  <rate>120.00</rate>
                </mode>
              </monitor>
            </logicalmonitor>
          </configuration>
          <configuration>
            <logicalmonitor>
              <x>6144</x>
              <y>0</y>
              <scale>0.75</scale>
              <primary>no</primary>
              <transform>
                <rotation>right</rotation>
              <monitor>
                <monitorspec>
                  <connector>DP-4</connector>
                </monitorspec>
                <mode>
                  <width>3840</width>
                  <height>2160</height>
                  <rate>60.00</rate>
                </mode>
              </monitor>
            </logicalmonitor>
          </configuration>
        </monitors>
      ''
    }"
  ];
}
