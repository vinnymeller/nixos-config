#!/bin/sh
xrandr \
    --output HDMI-0 --off \
    --output DP-0 --off \
    --output DP-1 --off \
    --output DP-2 --primary --mode 7680x2160 --pos 0x909 --rotate normal --rate 120.00 --scale 0.75x0.75 \
    --output DP-3 --off \
    --output DP-4 --mode 3840x2160 --pos 6144x0 --rotate right --rate 60.00 --scale 0.75x0.75 \
    --output DP-5 --off
