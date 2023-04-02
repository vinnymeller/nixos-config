#!/usr/bin/env bash

if ! command -v scrot &>/dev/null || ! command -v xclip &>/dev/null; then
    echo "Error: scrot and xclip must be installed to run this script."
    exit 1
fi
screenshot=$(mktemp /tmp/screenshot-XXXXXX.png)

# disable shellcheck causing warning in nix
# shellcheck disable=SC2016
scrot -e 'xclip -selection clipboard -t image/png -i $f' -s "$screenshot"

if command -v notify-send &>/dev/null; then
    notify-send "Screenshot saved to $screenshot"
fi
