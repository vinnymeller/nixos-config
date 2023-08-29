#!/bin/sh
xrandr \
    --output HDMI-0 --primary --mode 2560x1440 --pos 6119x720 --rotate normal --rate 144.01 \
    --output DP-0 --mode 3840x2160 --pos 2279x0 --rotate normal --rate 60.00 \
    --output DP-1 --off \
    --output DP-2 --mode 5120x1440 --pos 2749x2160 --rotate normal --rate 120.00 \
    --output DP-3 --off \
    --output DP-4 --off \
    --output DP-5 --off
