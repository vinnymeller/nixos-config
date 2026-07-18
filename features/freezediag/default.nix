# Diagnostics for the intermittent graphical freeze on vinnix (RTX 3090 /
# Hyprland) — both the "1 fps" render stalls and the harder full session lockups
# where even a VT switch fails. The compositor's own log lives on tmpfs
# ($XDG_RUNTIME_DIR/hypr/<instance>/hyprland.log) and is wiped by the hard reboot
# a freeze forces, and a *user*-level sampler dies with a frozen session, so this
# feature captures — into the PERSISTENT journal — what we otherwise can't
# recover after the fact:
#
#   1. gpu-watch (SYSTEM) — a periodic `nvidia-smi` snapshot run by the *system*
#                           manager, so it keeps sampling even when the user
#                           session is frozen. If the samples STOP during a hang,
#                           nvidia-smi itself hung => GPU/driver wedged; if they
#                           keep flowing, the GPU is fine and the freeze is in the
#                           compositor/session. A 15s start-timeout records a hung
#                           nvidia-smi as a failure instead of silently stalling.
#   2. hypr-log-mirror    — streams the live Hyprland log into the journal so the
#                           compositor's render log survives the reboot. (user)
#   3. sysctls            — full Magic SysRq + a short hung-task timeout so a
#                           freeze self-documents (see below).
#
# Kernel / NVRM `Xid` messages are already captured by persistent journald.
#
# DURING a hang (the base system stays alive — sshd + Tailscale are up — so SSH
# in from another device rather than fighting the dead TTY):
#   Alt+SysRq+W        -> dump blocked / D-state tasks to the kernel log (the tell)
#   Alt+SysRq+T        -> dump all task states
#   Alt+SysRq+S,+U,+B  -> sync, remount-ro, reboot (cleaner than a power cycle)
#
# AFTER a freeze + reboot, inspect the boot that froze (-1):
#   journalctl -u gpu-watch       -b -1 --since -10min   # GPU state into the stall (system unit)
#   journalctl --user -t hypr-log -b -1 --since -10min   # compositor log up to the freeze
#   journalctl -k                 -b -1 --since -10min   # kernel: SysRq/hung-task dumps, Xid
#
# Standalone feature so it's trivial to disable/remove once the freeze is fixed.
{
  nixos =
    { ... }:
    let
      # Stable NixOS symlink to the current system's nvidia-smi (host has
      # hardware.nvidia enabled). Resolved at runtime, so it tracks driver bumps.
      nvidiaSmi = "/run/current-system/sw/bin/nvidia-smi";
    in
    {
      # System-level GPU sampler: keeps logging even if the user session freezes,
      # which is what let the previous incident's cause slip through (the old
      # user-level sampler died with the session).
      systemd.services.gpu-watch = {
        description = "Snapshot nvidia-smi to the journal (system-level freeze diagnosis)";
        serviceConfig = {
          Type = "oneshot";
          # If nvidia-smi blocks on a wedged GPU, fail after 15s so the hang is
          # recorded rather than silently stalling the sampler.
          TimeoutStartSec = "15s";
          ExecStart =
            "${nvidiaSmi} "
            + "--query-gpu=timestamp,pstate,utilization.gpu,utilization.memory,"
            + "memory.used,memory.total,temperature.gpu,power.draw,clocks.sm,"
            + "clocks_throttle_reasons.active "
            + "--format=csv,noheader";
        };
      };
      systemd.timers.gpu-watch = {
        description = "Periodic system-level nvidia-smi snapshot for freeze diagnosis";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnBootSec = "2m";
          OnUnitActiveSec = "30s";
          AccuracySec = "1s";
        };
      };

      # Make a freeze self-document:
      #  - sysrq=1 enables all Magic SysRq functions (Alt+SysRq+W/T dumps, +S/+U/+B
      #    recovery). The kernel's default here was 16 (sync-only).
      #  - hung_task_timeout_secs=20 auto-dumps blocked tasks after 20s instead of
      #    the 120s default (longer than we tend to wait before rebooting).
      boot.kernel.sysctl = {
        "kernel.sysrq" = 1;
        "kernel.hung_task_timeout_secs" = 20;
      };
    };

  home =
    { pkgs, ... }:
    let
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
