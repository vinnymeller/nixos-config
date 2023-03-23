{ config, pkgs, ... }: {

    programs.kitty = {
        enable = true;
        font = {
            name = "Jetbrains Mono";
            package = pkgs.jetbrains-mono;
        };
        extraConfig = ''
            background_opacity   0.85
            map ctrl+c          copy_or_interrupt
        '';
    };
}
