{ config, pkgs, ... }: {

    programs.kitty = {
        enable = true;
        font = {
            name = "Jetbrains Mono";
            package = pkgs.jetbrains-mono;
        };

        extraConfig = ''
        background_opacity   0.85
        confirm_os_window_close 0
        map ctrl+f send_text all ~/.local/bin/tsesh open\x0d
        '';
    };
}
