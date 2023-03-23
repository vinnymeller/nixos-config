{ services, ... }: {

    services.xserver.enable = true;
    services.xserver.displayManager.sddm.enable = true;
    services.xserver.desktopManager.plasma5.enable = true;
    services.xserver.autoRepeatDelay = 200;
    services.xserver.autoRepeatInterval = 45;
    services.xserver.autorun = true;
}
