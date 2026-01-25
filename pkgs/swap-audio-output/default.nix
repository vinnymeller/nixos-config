{ pkgs, ... }:

with pkgs;

writeShellApplication {
  name = "swap-audio-output";
  runtimeInputs = [
    bash
    coreutils
    libnotify
    wireplumber
  ];

  text = builtins.readFile ./swap-audio-output.sh;
}
