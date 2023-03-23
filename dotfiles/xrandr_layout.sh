#!/bin/sh
xrandr \
    --output HDMI-0 --off \
    --output DP-0 --mode 5120x1440 --pos 708x2160 --rotate normal \
    --output DP-1 --off \
    --output DP-2 --primary --mode 2560x1440 --pos 3840x720 --rotate normal \
    --output DP-3 --off \
    --output DP-4 --mode 3840x2160 --pos 0x0 --rotate normal \
    --output DP-5 --off
