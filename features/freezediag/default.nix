# Diagnostics for the intermittent "1 fps but not crashed" graphical freeze on
# vinnix (RTX 3090 / Hyprland). The compositor's own log lives on tmpfs
# ($XDG_RUNTIME_DIR/hypr/<instance>/hyprland.log) and is wiped by the hard reboot
# a freeze forces, so this feature captures the two things we can't otherwise
# recover after the fact, into the PERSISTENT journal:
#
#   1. gpu-watch          — a periodic `nvidia-smi` snapshot (util / VRAM / pstate
#                           / throttle reasons / power / temp). Tells us whether
#                           the GPU was pegged, throttled, VRAM-starved, or stuck
#                           in a low power state during the stall.
#   2. hypr-log-mirror    — streams the live Hyprland log into the journal so the
#                           compositor's render log survives the reboot.
#
# Kernel / NVRM `Xid` messages are already captured by persistent journald, so
# they need no handling here.
#
# After a freeze, inspect the previous boot with:
#   journalctl --user -u gpu-watch -b -1 --since -10min
#   journalctl --user -t hypr-log  -b -1 --since -10min
#
# This is intentionally a standalone feature so it's trivial to disable/remove
# once the freeze is understood.
{
  home =
    { pkgs, ... }:
    let
      # Stable NixOS symlink to the *current* system's nvidia-smi (host has
      # hardware.nvidia enabled). Resolved at runtime, so it tracks driver bumps.
      nvidiaSmi = "/run/current-system/sw/bin/nvidia-smi";

      # The Hyprland instance dir under $XDG_RUNTIME_DIR/hypr has a per-boot
      # random name, and a new one appears if the compositor restarts, so we
      # track the newest hyprland.log and re-attach when it changes.
      hyprLogMirror = pkgs.writeShellScript "hypr-log-mirror" ''
        set -u
        runtime="''${XDG_RUNTIME_DIR:-/run/user/$(${pkgs.coreutils}/bin/id -u)}"
        dir="$runtime/hypr"
        cur=""
        tailpid=""
        cleanup() { [ -n "$tailpid" ] && kill "$tailpid" 2>/dev/null || true; }
        trap cleanup EXIT INT TERM
        while :; do
          log="$(${pkgs.coreutils}/bin/ls -dt "$dir"/*/hyprland.log 2>/dev/null | ${pkgs.coreutils}/bin/head -1 || true)"
          if [ -n "$log" ] && [ "$log" != "$cur" ]; then
            cleanup
            cur="$log"
            echo ">>> mirroring $log"
            ${pkgs.coreutils}/bin/tail -n +1 -F "$log" &
            tailpid=$!
          fi
          ${pkgs.coreutils}/bin/sleep 10
        done
      '';
    in
    {
      # --- 1. periodic GPU snapshot -> journal ---------------------------------
      systemd.user.services.gpu-watch = {
        Unit.Description = "Snapshot nvidia-smi to the journal (graphics-freeze diagnosis)";
        Service = {
          Type = "oneshot";
          ExecStart =
            "${nvidiaSmi} "
            + "--query-gpu=timestamp,pstate,utilization.gpu,utilization.memory,"
            + "memory.used,memory.total,temperature.gpu,power.draw,clocks.sm,"
            + "clocks_throttle_reasons.active "
            + "--format=csv,noheader";
        };
      };
      systemd.user.timers.gpu-watch = {
        Unit.Description = "Periodic nvidia-smi snapshot for freeze diagnosis";
        Timer = {
          OnBootSec = "2m";
          OnUnitActiveSec = "30s";
          AccuracySec = "1s";
        };
        Install.WantedBy = [ "timers.target" ];
      };

      # --- 2. mirror the live Hyprland log into the persistent journal ---------
      systemd.user.services.hypr-log-mirror = {
        Unit = {
          Description = "Mirror the live Hyprland log into the persistent journal";
          PartOf = [ "graphical-session.target" ];
          After = [ "graphical-session.target" ];
        };
        Service = {
          ExecStart = "${hyprLogMirror}";
          Restart = "always";
          RestartSec = "5s";
          SyslogIdentifier = "hypr-log";
        };
        Install.WantedBy = [ "graphical-session.target" ];
      };
    };
}
