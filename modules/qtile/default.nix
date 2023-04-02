{ services, ... }: {

    home.file.".config/qtile".source = ../../dotfiles/qtile;

    services.xserver = {
        enable = true;
        autorun = true;
        autoRepeatDelay = 200;
        autoRepeatInterval = 45;
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
        windowManager.qtile.enable = true;
    };
}
