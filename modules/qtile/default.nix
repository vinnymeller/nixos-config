{ config, pkgs, services, ... }: {

  services.xserver = {
    enable = true;
    autorun = true;
    autoRepeatDelay = 200;
    autoRepeatInterval = 50;
    upscaleDefaultCursor = false;
    displayManager = {
      gdm.enable = true;
      gdm.wayland = true;
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
      backend = "wayland";
      extraPackages = ps: with ps; [
	pywlroots
	pywayland
	xkbcommon
      ];
    };
    windowManager.session = [{
      name = "qtile";
      start = ''
        ${pkgs.qtile-unwrapped}/bin/qtile start -b wayland \
	--log-level INFO \
        --config $HOME/.config/qtile/config.py &
        waitPID=$!
      '';
    }];
    layout = "us";
    videoDrivers = [ "nvidia" ];
  };

  hardware.nvidia = {
    modesetting.enable = true;
    package = config.boot.kernelPackages.nvidiaPackages.beta;
  };

  hardware.opengl = {
    enable = true;
    driSupport = true;
    driSupport32Bit = true;
  };

  programs.xwayland.enable = true;


  environment.systemPackages = with pkgs; [
    wlroots
    xwayland
  ];

  # services.picom = {
  #   enable = true;
  #   backend = "glx";
  #   fade = true;
  #   fadeDelta = 5;
  #   opacityRules = [
  #     "100:QTILE_INTERNAL:32c"
  #   ];
  #   shadow = true;
  #   shadowOpacity = 0.5;
  # };
}
