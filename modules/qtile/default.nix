{ services, ... }: {

    services.xserver = {
        enable = true;
        autorun = true;
        autoRepeatDelay = 200;
        autoRepeatInterval = 45;
        upscaleDefaultCursor = false;
        displayManager = {
            gdm.enable = true;
            setupCommands = ''
                ~/.nixdots/dotfiles/xrandr_layout.sh
                xset dpms 0 0 0 && xset s noblank && xset s off
            '';
        };
        windowManager.qtile.enable = true;
    };
}
