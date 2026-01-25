{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.mine.kitty;
in
{
  options.mine.kitty = {
    enable = mkEnableOption "Enable kitty terminal.";
  };

  config = mkIf cfg.enable {

    programs.kitty = {
      enable = true;
      font = {
        # name = "Jetbrains Mono";
        # package = pkgs.jetbrains-mono;
        name = "0xProto Nerd Font"; # test out 0xProto. I love JBM, but this looked neat
        package = pkgs.nerd-fonts._0xproto;
        # name = "JetBrainsMono Nerd Font";
        # package = pkgs.nerd-fonts.jetbrains-mono;
      };

      shellIntegration.enableZshIntegration = true;
      extraConfig =
        let
          c = config.mine.colors;
        in
        ''
          term xterm-kitty
          background_opacity   0.85
          confirm_os_window_close 0
          enable_audio_bell    no

          cursor                  ${c.gray}
          cursor_text_color       background

          url_color               ${c.blue-bright}

          visual_bell_color       ${c.cyan-bright}
          bell_border_color       ${c.cyan-bright}

          active_border_color     ${c.magenta-bright}
          inactive_border_color   ${c.black}

          foreground              ${c.fg}
          background              ${c.bg-dark}
          selection_foreground    ${c.gray}
          selection_background    ${c.fg}

          active_tab_foreground   ${c.fg0}
          active_tab_background   ${c.black}
          inactive_tab_foreground ${c.white}
          inactive_tab_background ${c.bg1}

          # black  (bg3/bg4)
          color0                  ${c.black}
          color8                  ${c.black-bright}

          # red
          color1                  ${c.red}
          color9                  ${c.red-bright}

          #: green
          color2                  ${c.green}
          color10                 ${c.green-bright}

          # yellow
          color3                  ${c.yellow}
          color11                 ${c.yellow-bright}

          # blue
          color4                  ${c.blue}
          color12                 ${c.blue-bright}

          # purple
          color5                  ${c.magenta}
          color13                 ${c.magenta-bright}

          # aqua
          color6                  ${c.cyan}
          color14                 ${c.cyan-bright}

          # white (fg4/fg3)
          color7                  ${c.white}
          color15                 ${c.white-bright}
        '';
    };
  };
}
