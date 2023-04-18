{ pkgs, use-notify ? true, ... }:

with pkgs;

writeShellApplication {
    name = "screenshot_to_clipboard";
    runtimeInputs = [
        bash
        xclip
        scrot
        (if use-notify then libnotify else null)
    ];

    text = builtins.readFile ../../scripts/screenshot_to_clipboard.sh;
}
