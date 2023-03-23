{ services, ... }: {

    services.xserver = {
        enable = true;
        autorun = true;
        autoRepeatDelay = 200;
        autoRepeatInterval = 45;
        displayManager = {
            lightdm.enable = true;
            # sessionCommands = ''
            #     ~/.nixdots/dotfiles/xrandr_layout.sh
            #     xset dpms 0 0 0 && xset s noblank && xset s off
            # '';
        };
        windowManager.qtile.enable = true;
    };
}
