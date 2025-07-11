# nixos-config

## TODOS:

1. Make audio output toggle more flexible OR find a good existing solution



## Random notes:

### Hyprland / Wayland screen sharing

My issues seemed to ALL stem from having both the nvidia and amd igpu enabled. Disabling the igpu in the BIOS fixed pretty much everything:
  - hardware acceleration in electron apps
