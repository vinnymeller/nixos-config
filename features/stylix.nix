{
  nixos =
    {
      config,
      pkgs,
      ...
    }:
    let
      c = config.features.defaults.colors;
    in
    {
      # Stylix themes the long tail of apps we don't hand-configure (bat, btop,
      # fzf, firefox, gtk, qt, ...) from a single base16 scheme. The scheme is
      # derived from features.defaults.colors so that palette stays the single
      # source of truth. Targets we style by hand are disabled in `home` below.
      #
      # Set at the NixOS level on purpose: stylix's home-manager integration
      # copies these into HM with lib.mkDefault, mirroring how lib/default.nix
      # propagates features.defaults.colors. HM-level overrides still win.
      stylix = {
        enable = true;
        polarity = "dark";

        # base16.nix trims the leading '#', so palette values pass through as-is.
        base16Scheme = {
          base00 = c.bg; # default background
          base01 = c.bg1; # lighter background (status bars)
          base02 = c.bg2; # selection background
          base03 = c.black; # comments, invisibles
          base04 = c.white-bright; # dark foreground (status bars)
          base05 = c.fg2; # default foreground
          base06 = c.fg; # light foreground
          base07 = c.fg0; # lightest foreground
          base08 = c.red-bright; # variables, errors
          # base09/base0F have no counterpart in features.defaults.colors, which
          # carries no orange. These are the canonical gruvbox-dark values; move
          # them into the palette if anything else ever needs them.
          base09 = "#fe8019"; # integers, constants (gruvbox orange)
          base0A = c.yellow-bright; # classes, search highlight
          base0B = c.green-bright; # strings
          base0C = c.cyan-bright; # escapes, regex
          base0D = c.blue-bright; # functions
          base0E = c.magenta-bright; # keywords
          base0F = "#d65d0e"; # deprecated (gruvbox dark orange)
        };

        fonts.monospace = {
          package = pkgs.nerd-fonts._0xproto;
          name = "0xProto Nerd Font";
        };
      };
    };

  home =
    { ... }:
    {
      # stylix.targets.* is NOT propagated from NixOS to HM (only
      # targets.qt.platform is), and these targets are all HM-only, so the
      # opt-outs have to live here.
      stylix.targets = {
        # features/kitty.nix sets colors by hand and deliberately deviates from
        # base16 (pure black background, gruvbox bg3 as color0).
        kitty.enable = false;
        # features/hyprland uses configType = "lua"; stylix writes hyprlang
        # settings, which do not apply to that backend.
        hyprland.enable = false;
        # features/hyprland hand-themes dunst: per-urgency background/
        # foreground/frame_color from the palette plus a Nerd Font for glyphs.
        # Stylix would set all of those from sansSerif/base16 and conflict.
        dunst.enable = false;
        # features/hyprland gives hyprlock a blurred-wallpaper background (a
        # list of background blocks); stylix sets a flat { color = ...; }
        # attrset, which collides on type as well as intent.
        hyprlock.enable = false;

        # These two apps write their own config files, which already exist with
        # real settings in them (~/.config/spotify-player/app.toml carries a
        # client_id and custom playback format; vesktop's settings.json is 12KB
        # of Vencord plugin config). Enabling these targets makes home-manager
        # own those paths, replacing their contents and turning them into
        # read-only store symlinks -- so vesktop could no longer save settings
        # at all. Enable only after porting the settings into Nix.
        spotify-player.enable = false;
        vesktop.enable = false;
      };
    };
}
