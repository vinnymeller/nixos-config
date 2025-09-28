{ pkgs, ... }:

with pkgs;

writeShellApplication {
  name = "rofi-chrome-profile-launcher";
  runtimeInputs = [
    bash
    python3
    google-chrome
  ];

  text = builtins.readFile ../../scripts/rofi-chrome-profile-launcher.sh;
}
