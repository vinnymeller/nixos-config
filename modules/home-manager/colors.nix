{ lib, ... }:
{
  options.mine.colors = lib.mkOption {
    type = lib.types.attrsOf lib.types.str;
    default = {
      # Backgrounds (dark to light)
      bg = "#282828"; # bg0
      bg-dark = "#000000"; # your custom
      bg1 = "#3c3836";
      bg2 = "#504945";

      # Foregrounds (light to dark)
      fg = "#ebdbb2"; # fg1
      fg0 = "#fbf1c7"; # brightest
      fg2 = "#d5c4a1";

      # Neutral gray (between bg and fg)
      gray = "#928374";

      # ANSI colors (normal)
      black = "#665c54"; # bg3
      red = "#cc241d";
      green = "#98971a";
      yellow = "#d79921";
      blue = "#458588";
      magenta = "#b16286";
      cyan = "#689d6a";
      white = "#a89984"; # fg4

      # ANSI colors (bright)
      black-bright = "#7c6f64"; # bg4
      red-bright = "#fb4934";
      green-bright = "#b8bb26";
      yellow-bright = "#fabd2f";
      blue-bright = "#83a598";
      magenta-bright = "#d3869b";
      cyan-bright = "#8ec07c";
      white-bright = "#bdae93"; # fg3
    };
  };
}
