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
        "$terminal" = "kitty";
        "$browser" = "google-chrome-stable";

        monitor = [
          "DP-4, 7680x2160@120.00, 0x0, 1.5"
          "DP-3, 3840x2160@60.00, 5120x-559, 1.5, transform, 3"
        ];
        workspace = [
          "1,monitor:DP-4"
          "2,monitor:DP-4"
          "3,monitor:DP-4"
          "4,monitor:DP-4"
          "5,monitor:DP-4"
          "6,monitor:DP-3"
          "7,monitor:DP-3"
          "8,monitor:DP-3"
          "9,monitor:DP-3"
          "0,monitor:DP-3"
        ];
        bindm = [
          "$mod, mouse:272, movewindow"
          "$mod, mouse:273, resizewindow"
          "$mod ALT, mouse:272, movewindow"
        ];
        bind =
          [
            "$mod, B, exec, $browser"
            "$mod, T, exec, uwsm app -- $terminal"
            "$mod, RETURN, exec, $terminal"
            "$mod, SPACE, exec, rofi -show drun"

            "$mod ALT, L, exec, hyprlock"

            "$mod, W, killactive"
            "$mod, F, fullscreen"
            "$mod, R, togglesplit"
            "$mod, V, togglefloating"
            "$mod, U, focusurgentorlast"
            "$mod, TAB, focuscurrentorlast"

            "$mod, h, movefocus, l"
            "$mod, l, movefocus, r"
            "$mod, j, movefocus, d"
            "$mod, k, movefocus, u"
            "$mod SHIFT, h, movewindow, l"
            "$mod SHIFT, l, movewindow, r"
            "$mod SHIFT, j, movewindow, d"
            "$mod SHIFT, k, movewindow, u"

            "$mod CTRL, h, resizeactive, -50 0"
            "$mod CTRL, l, resizeactive, 50 0"
            "$mod CTRL, j, resizeactive, 0 -50"
            "$mod CTRL, k, resizeactive, 0 50"

            "$mod, G, togglegroup"
            "$mod CTRL, N, changegroupactive, f"
            "$mod CTRL, P, changegroupactive, b"

            # cycle workspaces
            "$mod, bracketleft, workspace, m-1"
            "$mod, bracketright, workspace, m+1"

            # cycle monitors
            "$mod CTRL, bracketleft, focusmonitor, l"
            "$mod CTRL, bracketright, focusmonitor, r"
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
          "_JAVA_AWT_WM_NONREPARENTING,1"
          "QT_WAYLAND_DISABLE_WINDOWDECORATION,1"
          "QT_QPA_PLATFORM,wayland"
          "SDL_VIDEODRIVER,wayland"
          "GDK_BACKEND,wayland"
          "LIBVA_DRIVER_NAME,nvidia"
          "XDG_SESSION_TYPE,wayland"
          "XDG_SESSION_DESKTOP,Hyprland"
          "XDG_CURRENT_DESKTOP,Hyprland"
          "GBM_BACKEND,nvidia-drm"
          "__GLX_VENDOR_LIBRARY_NAME,nvidia"
        ];
        ecosystem = {
          no_update_news = true;
          no_donation_nag = true;
        };
        misc = {
          disable_hyprland_logo = true;
          disable_splash_rendering = true;
        };
        exec-once = [
          "${pkgs.hyprpaper}/bin/hyprpaper"
        ];
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
  };
}
