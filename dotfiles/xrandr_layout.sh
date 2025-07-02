#!/bin/sh
# come back to trying to get fractional scaling working nicely
# source of the scaling stuff: https://web.archive.org/web/20240121070644/https://wilfredwee.github.io/entry/how-to-xrandr
# I like how 2k looks on a 27", 4k on 32" is too small still, 4k is 1.5x each dimension of 2k, 1.25x instead of 1.5x gives 3200x1800 and seems pretty good. so I want my perceived resolution on a 4k monitor to be 3200x1800
xrandr \
    --output HDMI-0 --off \
    --output DP-0 --mode 3840x2160 --pos 7680x0 --rotate right --rate 60.00 \
    --output DP-1 --off \
    --output DP-2 --primary --mode 7680x2160 --pos 0x909 --rotate normal --rate 120.00 \
    --output DP-3 --off \
    --output DP-4 --off \
    --output DP-5 --off

# split virtual monitors for screen sharing
xrandr --setmonitor LEFT 3840/697x2160/392+0+909 none
xrandr --setmonitor RIGHT 3840/697x2160/392+3840+909 none
xrandr --fb 9840x3840
