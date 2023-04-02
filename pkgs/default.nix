{ pkgs ? import <nixpkgs> { } }:
with pkgs; {
    screenshot_to_clipboard = callPackage ./screenshot_to_clipboard { };
}
