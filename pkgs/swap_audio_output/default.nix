{ pkgs, ... }:

with pkgs;

writeShellApplication {
  name = "swap_audio_output";
  runtimeInputs = [
    bash
    coreutils
    libnotify
    wireplumber
  ];

  text = builtins.readFile ../../scripts/swap_audio_output.sh;
}
