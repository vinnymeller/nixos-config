{ pkgs, ... }:

with pkgs;

writeShellApplication {
    name = "discord_audio_share";
    runtimeInputs = [
        bash
        pulseaudio
    ];

    text = builtins.readFile ../../scripts/discord_audio_share.sh;
}
