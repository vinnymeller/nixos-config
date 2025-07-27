#!/usr/bin/env bash

HEADSET_NAME="alsa_output.usb-Kingston_HyperX_QuadCast_S_4100-00.analog-stereo"
SPEAKER_NAME="alsa_output.usb-SteelSeries_SteelSeries_Arena_7-00.analog-stereo"


CURRENT_DEFAULT=$(wpctl inspect @DEFAULT_AUDIO_SINK@ | grep 'node.name' | awk '{print $NF}' | tr -d '"')

TARGET_NAME=""
SUCCESS_MESSAGE=""
ICON=""

if [ "$CURRENT_DEFAULT" = "$HEADSET_NAME" ]; then
	TARGET_NAME="$SPEAKER_NAME"
	SUCCESS_MESSAGE="🔊 Switched to Speakers (SteelSeries Arena 7)"
	ICON="audio-speakers"
else
	TARGET_NAME="$HEADSET_NAME"
	SUCCESS_MESSAGE="🎧 Switched to Headset (HyperX QuadCast S)"
	ICON="audio-headphones"
fi

TARGET_ID=$(wpctl status -n | grep "$TARGET_NAME" | head -n 1 | tr -d "│ *" | awk -F'[.]' '{print $1}')

if [ -n "$TARGET_ID" ]; then
	wpctl set-default "$TARGET_ID"
	notify-send "$SUCCESS_MESSAGE" --icon="$ICON"
else
	notify-send "Error: Device not found" --icon=audio-headphones
	exit 1
fi
