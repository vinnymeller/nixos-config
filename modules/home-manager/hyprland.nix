{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.mine.hyprland;
in
{
  options.mine.hyprland = {
    enable = mkEnableOption "Enable Hyprland.";
  };

  config = mkIf cfg.enable {
    wayland.windowManager.hyprland = {
      enable = true;
      package = inputs.hyprland.packages.${pkgs.system}.hyprland;
      portalPackage = inputs.hyprland.packages.${pkgs.system}.xdg-desktop-portal-hyprland;
      xwayland.enable = true;
      systemd.variables = [ "--all" ];
      settings = {
        "$mod" = "SUPER";
        "$switch" = "CTRL ALT";
        "$supsw" = "SUPER CTRL ALT";
        "$meh" = "CTRL ALT SHIFT";
        "$god" = "SUPER CTRL ALT SHIFT";
        "$ml" = "DP-2";
        "$mr" = "DP-1";

        "$terminal" = "kitty";
        "$browser" = "google-chrome-stable";
        "$filemanager" = "nemo";

        monitor = [
          "$ml, 7680x2160@120.00, 0x0, 1.5"
          "$mr, 3840x2160@60.00, 5120x-559, 1.5, transform, 3"
        ];
        workspace = [
          "1,monitor:$ml"
          "2,monitor:$ml"
          "3,monitor:$ml"
          "4,monitor:$ml"
          "5,monitor:$ml"
          "6,monitor:$mr"
          "7,monitor:$mr"
          "8,monitor:$mr"
          "9,monitor:$mr"
          "0,monitor:$mr"
        ];
        bindm = [
          "$mod, mouse:272, movewindow"
          "$mod, mouse:273, resizewindow"
          "$mod ALT, mouse:272, movewindow"
        ];
        bind = [
          "$mod, B, exec, $browser"
          "$mod, D, exec, $filemanager"
          "$mod, T, exec, uwsm app -- $terminal"
          "$mod, RETURN, exec, $terminal"
          "$mod, SPACE, exec, rofi -theme gruvbox-dark -show drun"
          "$mod, V, exec, $terminal --class clipse -e clipse"
          "$mod CTRL, S, exec, hyprshot -m region output --clipboard-only"
          "$mod SHIFT ALT, L, exec, hyprlock"
          "$mod, W, killactive"
          "$mod, R, togglefloating"
          "$mod, U, focusurgentorlast"
          "$mod, TAB, focuscurrentorlast"
          "$mod, F, fullscreen"
          "$mod CTRL, F, fullscreenstate, 0, 2"
          "$mod, P, pin"
          "$mod, h, movefocus, l"
          "$mod, l, movefocus, r"
          "$mod, j, movefocus, d"
          "$mod, k, movefocus, u"
          "$mod CTRL, h, movewindow, l"
          "$mod CTRL, l, movewindow, r"
          "$mod CTRL, j, movewindow, d"
          "$mod CTRL, k, movewindow, u"
          "$mod SHIFT, h, resizeactive, -50 0"
          "$mod SHIFT, l, resizeactive, 50 0"
          "$mod SHIFT, j, resizeactive, 0 -50"
          "$mod SHIFT, k, resizeactive, 0 50"
          "$mod, G, togglegroup"
          "$mod CTRL, G, moveoutofgroup"
          "$mod CTRL, N, changegroupactive, f"
          "$mod CTRL, P, changegroupactive, b"
          # cycle workspaces
          "$mod, bracketleft, workspace, m-1"
          "$mod, bracketright, workspace, m+1"
          # cycle monitors
          "$mod CTRL, bracketleft, focusmonitor, l"
          "$mod CTRL, bracketright, focusmonitor, r"

          # God keybinds
          "$god, O, exec, swap-audio-output"
          "$god, P, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.05+"
          "$god, N, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.05-"
          "$god, R, exec, hyprctl hyprsunset temperature -500"
          "$god, D, exec, hyprctl hyprsunset temperature 6500"
          "$god, B, exec, hyprctl hyprsunset temperature +500"

        ]
        ++ (builtins.concatLists (
          builtins.genList (
            i:
            let
              ws = i + 1;
            in
            [
              "$mod, code:1${toString i}, workspace, ${toString ws}"
              "$mod SHIFT, code:1${toString i}, movetoworkspace, ${toString ws}"
              "$mod CTRL, code:1${toString i}, movetoworkspacesilent, ${toString ws}"
            ]
          ) 9
        ));
        windowrulev2 = [
          "float,class:(clipse)"
          "float,class:(nemo)"
          "float,class:(feh)"
          "size 622 652,class:(clipse)"
          "stayfocused,class:(clipse)"
          "stayfocused,class:(gcr-prompter)"

          # bw popups
          "float,class:(chrome-nngceckbapebfimnlniiiahkandclblb-.*)"
          "stayfocused,class:(chrome-nngceckbapebfimnlniiiahkandclblb-.*)"
        ];
        general = {
          gaps_in = 0;
          gaps_out = 0;
          border_size = 1;
          allow_tearing = true;
          "col.active_border" = "rgb(ff5757)";
          snap = {
            enabled = true;
          };
        };
        group = {
          groupbar = {
            render_titles = false;
            "col.active" = "rgb(ffff80)";
            "col.inactive" = "rgb(b5b5b5)";
          };
        };
        input = {
          repeat_delay = 200;
          repeat_rate = 50;
          kb_layout = "us";
          follow_mouse = 2; # 2 = keyboard only follows if click on new window
        };
        cursor = {
          no_hardware_cursors = 2;
          default_monitor = "$ml";
        };
        xwayland = {
          enabled = true;
          force_zero_scaling = true;

        };
        animations = {
          enabled = true;
          bezier = [
            "linear, 0, 0, 1, 1"
            "md3_standard, 0.2, 0, 0, 1"
            "md3_decel, 0.05, 0.7, 0.1, 1"
            "md3_accel, 0.3, 0, 0.8, 0.15"
            "overshot, 0.05, 0.9, 0.1, 1.1"
            "crazyshot, 0.1, 1.5, 0.76, 0.92"
            "hyprnostretch, 0.05, 0.9, 0.1, 1.0"
            "menu_decel, 0.1, 1, 0, 1"
            "menu_accel, 0.38, 0.04, 1, 0.07"
            "easeInOutCirc, 0.85, 0, 0.15, 1"
            "easeOutCirc, 0, 0.55, 0.45, 1"
            "easeOutExpo, 0.16, 1, 0.3, 1"
            "softAcDecel, 0.26, 0.26, 0.15, 1"
            "md2, 0.4, 0, 0.2, 1"
          ];
          animation = [
            "windows, 1, 3, md3_decel, popin 60%"
            "windowsIn, 1, 3, md3_decel, popin 60%"
            "windowsOut, 1, 3, md3_accel, popin 60%"
            "border, 1, 10, default"
            "fade, 1, 3, md3_decel"
            "layersIn, 1, 3, menu_decel, slide"
            "layersOut, 1, 1.6, menu_accel"
            "fadeLayersIn, 1, 2, menu_decel"
            "fadeLayersOut, 1, 4.5, menu_accel"
            "workspaces, 1, 7, menu_decel, slide"
            "specialWorkspace, 1, 3, md3_decel, slidevert"
          ];
        };
        env = [
          "NIXOS_OZONE_WL,1"
          "NVD_BACKEND,direct"
          "_JAVA_AWT_WM_NONREPARENTING,1"
          "QT_WAYLAND_DISABLE_WINDOWDECORATION,1"
          "QT_QPA_PLATFORM,wayland;xcb"
          "SDL_VIDEODRIVER,wayland"
          "CLUTTER_BACKEND,wayland"
          "GDK_BACKEND,wayland,x11,*"
          "LIBVA_DRIVER_NAME,nvidia"
          "XDG_SESSION_TYPE,wayland"
          "XDG_SESSION_DESKTOP,Hyprland"
          "XDG_CURRENT_DESKTOP,Hyprland"
          "GBM_BACKEND,nvidia-drm"
          "__GLX_VENDOR_LIBRARY_NAME,nvidia"
          "WLR_NO_HARDWARE_CURSORS,1"
          "AQ_DRM_DEVICES,/dev/dri/card2:/dev/dri/card1"
          "QT_AUTO_SCREEN_SCALE_FACTOR,1"
        ];
        ecosystem = {
          no_update_news = true;
          no_donation_nag = true;
        };
        misc = {
          disable_hyprland_logo = true;
          disable_splash_rendering = true;
        };
      };
    };
    services.hyprpaper = {
      enable = true;
      settings = {
        preload = [
          "${config.home.homeDirectory}/.nixdots/files/avatar-wallpaper.png"
        ];
        wallpaper = [
          ", ${config.home.homeDirectory}/.nixdots/files/avatar-wallpaper.png"
        ];
      };
    };
    services.clipse = {
      enable = true;
      imageDisplay.type = "kitty";
      historySize = 1000;
      allowDuplicates = false;
    };
    programs.hyprlock = {
      enable = true;
      settings = {
        general = {
          disable_loading_bar = true;
          grace = 0;
          hide_cursor = true;
          no_fade_in = false;
        };

        background = [
          {
            path = "${config.home.homeDirectory}/.nixdots/files/avatar-wallpaper.png";
            blur_passes = 3;
            blur_size = 8;
          }
        ];

        input-field = [
          {
            size = "300, 50";
            position = "0, -80";
            monitor = "";
            dots_center = true;
            fade_on_empty = false;
            shadow_passes = 2;
          }
        ];
      };
    };
    home.pointerCursor = {
      gtk.enable = true;
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Classic";
      size = 16;
    };

    services.hyprsunset = {
      enable = true;
    };

    gtk = {
      enable = true;

      gtk2.extraConfig = ''
        gtk-application-prefer-dark-theme=1
      '';

      gtk3.extraConfig = {
        gtk-application-prefer-dark-theme = true;
      };

      gtk4.extraConfig = {
        gtk-application-prefer-dark-theme = true;
      };

      theme = {
        package = pkgs.gruvbox-gtk-theme;
        name = "Gruvbox-Dark";
      };

      iconTheme = {
        package = pkgs.papirus-icon-theme;
        name = "Papirus-Dark";
      };

    };

    dconf = {
      enable = true;
      settings = {
        "org/gnome/desktop/interface" = {
          color-scheme = "prefer-dark";
        };
        "org/freedesktop/appearance" = {
          color-scheme = 1;
        };
      };
    };

    xdg.mimeApps = {
      enable = true;
      defaultApplications =
        let
          browser = "google-chrome.desktop";
          discord = "discord.desktop";
          imageViewer = "feh.desktop";
          videoPlayer = "vlc.desktop";
          editor = "nixCats.desktop";
          fileManager = "nemo.desktop";
        in
        {
          "text/html" = browser;
          "x-scheme-handler/http" = browser;
          "x-scheme-handler/https" = browser;
          "x-scheme-handler/about" = browser;
          "x-scheme-handler/unknown" = browser;
          "inode/directory" = fileManager;
          "text/plain" = editor;
          "application/pdf" = browser;
          "image/jpeg" = imageViewer;
          "image/png" = imageViewer;
          "image/gif" = imageViewer;
          "image/bmp" = imageViewer;
          "image/tiff" = imageViewer;
          "image/x-bmp" = imageViewer;
          "image/x-pcx" = imageViewer;
          "image/x-tga" = imageViewer;
          "image/x-portable-pixmap" = imageViewer;
          "image/x-portable-bitmap" = imageViewer;
          "image/heic" = imageViewer;
          "image/heif" = imageViewer;
          "application/pcx" = imageViewer;
          "video/mp4" = videoPlayer;
          "video/mpeg" = videoPlayer;
          "video/webm" = videoPlayer;
          "video/quicktime" = videoPlayer;
          "video/x-matroska" = videoPlayer;
          "video/x-msvideo" = videoPlayer;
          "video/x-flv" = videoPlayer;
          "video/3gpp" = videoPlayer;
          "video/3gpp2" = videoPlayer;
          "x-scheme-handler/discord" = discord;

        };
    };
    home.packages = with pkgs; [
      clipse
      google-chrome
      hyprshot
      libheif
      nemo-with-extensions
      rofi
      wl-clipboard
      dunst
      feh
      vlc
    ];
  };
}
