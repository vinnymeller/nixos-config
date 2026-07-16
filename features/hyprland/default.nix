{
  assertions =
    { features, ... }:
    [
      {
        assertion = features.kitty.enable;
        message = "features.hyprland requires features.kitty to be enabled (used as default terminal).";
      }
    ];

  nixos =
    {
      cfg,
      config,
      lib,
      pkgs,
      inputs,
      ...
    }:
    {
      programs.hyprland = {
        package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
        portalPackage =
          inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
        enable = lib.mkDefault true;
        withUWSM = lib.mkDefault true;
      };

      security.pam.services = {
        hyprlock = { };
        greetd.enableGnomeKeyring = lib.mkDefault true;
        login.enableGnomeKeyring = lib.mkDefault true;
      };

      services.greetd = {
        enable = lib.mkDefault true;
        useTextGreeter = lib.mkDefault true;
        settings = {
          default_session = {
            command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd start-hyprland";
            user = builtins.head cfg.users;
          };
        };
      };

      services.blueman.enable = lib.mkDefault true;

      services.pipewire = {
        enable = lib.mkDefault true;
        pulse.enable = lib.mkDefault true;
        alsa.enable = lib.mkDefault true;
        jack.enable = lib.mkDefault true;
      };

      services.gnome.gnome-keyring.enable = lib.mkDefault true;
      services.gvfs.enable = lib.mkDefault true;
      services.udisks2.enable = lib.mkDefault true;
      services.devmon.enable = lib.mkDefault true;

      programs.nm-applet.enable = true;
    };

  home =
    {
      cfg,
      lib,
      pkgs,
      hmConfig,
      ...
    }:
    let
      c = hmConfig.features.defaults.colors;
      toRgb = color: "rgb(${builtins.substring 1 6 color})";
    in
    {
      wayland.windowManager.hyprland = {
        enable = lib.mkDefault true;
        # Hyprland 0.55+ configures via Lua; hyprlang is deprecated. The full
        # config lives in ./hyprland.lua (a real Lua file -> LSP/luacheck) and is
        # inlined into ~/.config/hypr/hyprland.lua by the HM module through
        # `extraConfig`. The module's lua backend renders `settings` (below) as
        # `local` declarations *ahead* of extraConfig, and generates the
        # systemd/D-Bus startup hook from `systemd.variables`, so we hand-write
        # neither. See the header of ./hyprland.lua for the contract.
        configType = "lua";
        package = null;
        portalPackage = null;
        xwayland.enable = lib.mkDefault true;
        systemd.variables = [ "--all" ];
        # `_var` renders `local NIX = { ... }`. Single source of truth for the
        # handful of Nix-owned values the Lua config reads as NIX.colors.* /
        # NIX.features.*.
        settings = {
          NIX._var = {
            colors = {
              active_border = toRgb c.red-bright;
              group_active = toRgb c.yellow-bright;
              group_inactive = toRgb c.white;
            };
            features = {
              vtt = hmConfig.features.vtt.enable;
            };
          };
        };
        extraConfig = builtins.readFile ./hyprland.lua;
      };

      services.hyprpaper = {
        enable = lib.mkDefault true;
        settings = {
          splash = false;
          preload = [
            "${../../files/avatar-wallpaper.png}"
          ];
          wallpaper = [
            {
              monitor = "DP-2";
              path = "${../../files/avatar-wallpaper.png}";
            }
            {
              monitor = "DP-1";
              path = "${../../files/avatar-wallpaper.png}";
            }
          ];
        };
      };

      services.clipse = {
        enable = lib.mkDefault true;
        imageDisplay.type = "kitty";
        historySize = lib.mkDefault 1000;
        allowDuplicates = lib.mkDefault false;
      };

      services.dunst = {
        enable = lib.mkDefault true;
        iconTheme = {
          name = "Papirus-Dark";
          package = pkgs.papirus-icon-theme;
        };
        settings = {
          global = {
            width = "(200,500)";
            height = 400;
            offset = "30x50";
            origin = "top-right";
            frame_color = c.black;
            font = "0xProto Nerd Font 10";
            corner_radius = 8;
          };
          urgency_low = {
            background = c.bg;
            foreground = c.white;
            timeout = 5;
          };
          urgency_normal = {
            background = c.bg;
            foreground = c.fg;
            timeout = 10;
          };
          urgency_critical = {
            background = c.bg;
            foreground = c.red-bright;
            frame_color = c.red;
            timeout = 0;
          };
        };
      };

      programs.hyprlock = {
        enable = lib.mkDefault true;
        settings = {
          general = {
            disable_loading_bar = true;
            grace = 0;
            hide_cursor = true;
            no_fade_in = false;
          };
          background = [
            {
              path = "${../../files/avatar-wallpaper.png}";
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

      programs.rofi = {
        enable = lib.mkDefault true;
        theme = lib.mkDefault "gruvbox-dark";
        modes = [
          "window"
          "run"
          "ssh"
          "drun"
          "combi"
          "keys"
        ];
      };

      services.hyprsunset = {
        enable = lib.mkDefault true;
      };

      gtk = {
        enable = lib.mkDefault true;
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
        gtk2.theme = hmConfig.gtk.theme;
        gtk3.theme = hmConfig.gtk.theme;
        gtk4.theme = hmConfig.gtk.theme;
        iconTheme = {
          package = pkgs.papirus-icon-theme;
          name = "Papirus-Dark";
        };
      };

      dconf = {
        enable = lib.mkDefault true;
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
        enable = lib.mkDefault true;
        defaultApplications =
          let
            browser = "google-chrome.desktop";
            discord = "discord.desktop";
            imageViewer = "feh.desktop";
            videoPlayer = "vlc.desktop";
            editor = "nvim.desktop";
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

      home.packages =
        let
          heif-thumbnailer = pkgs.writeTextFile {
            name = "heif-thumbnailer";
            destination = "/share/thumbnailers/heif.thumbnailer";
            text = ''
              [Thumbnailer Entry]
              TryExec=heif-thumbnailer
              Exec=heif-thumbnailer -s %s %i %o
              MimeType=image/heif;image/avif;
            '';
          };
        in
        with pkgs;
        [
          clipse
          google-chrome
          hyprshot
          nemo-with-extensions
          wl-clipboard
          dunst
          feh
          vlc
          rofi-chrome-profile-launcher
          swap-audio-output
          pavucontrol

          # thumbnailers
          libheif
          heif-thumbnailer
          ffmpegthumbnailer
        ];
    };
}
