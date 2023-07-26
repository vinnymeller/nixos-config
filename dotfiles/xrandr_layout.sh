#!/bin/sh
xrandr \
    --output HDMI-0 --mode 3840x2160 --pos 132x362 --rate 60.00 --rotate normal \
    --output DP-0 --mode 5120x1440 --pos 910x2522 --rate 239.76 --rotate normal \
    --output DP-1 --off \
    --output DP-2 --primary --mode 2560x1440 --rate 143.85 --pos 3972x1082 --rotate normal \
    --output DP-3 --off \
    --output DP-4 --off \
    --output DP-5 --off
