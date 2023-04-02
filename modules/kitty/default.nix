{ config, pkgs, installKitty ? true, ... }: {

    programs.kitty = {
        enable = installKitty;
        font = {
            name = "Jetbrains Mono";
            package = pkgs.jetbrains-mono;
        };

        extraConfig = ''
        background_opacity   0.85
        confirm_os_window_close 0
        '';
    };
}
