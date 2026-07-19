# Freeze/crash resilience for vinnix (RTX 3090 / Hyprland): both PREVENT the
# intermittent hard-freeze and DIAGNOSE it if something still slips through.
#
# Root cause (confirmed from the kernel OOM log of the 2026-07-18 freeze): host
# memory exhaustion, NOT the GPU. Heavy Rust dev load — multiple rust-analyzer
# instances (~15G each) + a parallel cargo/rustc/rust-lld link storm + a browser
# — summed past 64G RAM and saturated the 8G disk swap, so the kernel thrashed on
# disk until it hard-locked, then its late OOM killer picked the wrong victim (a
# chrome tab, not the 28G of rust-analyzers). The GPU sat idle (fan off) the whole
# time. The "1 fps" render stalls and the full session lockups where even a VT
# switch fails are both faces of that thrash.
#
# PREVENTION (system):
#   - earlyoom — kill the biggest offender EARLY, before the disk-swap thrash,
#                aimed at the regenerable Rust toolchain and fenced off from the
#                compositor / sshd / session manager.
#   - zram     — compressed in-RAM swap, used before the disk partition, so
#                pressure degrades to a brief slowdown instead of a disk lockup.
#
# DIAGNOSIS: the compositor's own log lives on tmpfs
# ($XDG_RUNTIME_DIR/hypr/<instance>/hyprland.log) and is wiped by the hard reboot
# a freeze forces, and a *user*-level sampler dies with a frozen session, so this
# feature also captures — into the PERSISTENT journal — what we otherwise can't
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
#   journalctl -u earlyoom        -b -1                   # what earlyoom killed, and when
#   journalctl -u gpu-watch       -b -1 --since -10min   # GPU state into the stall (system unit)
#   journalctl --user -t hypr-log -b -1 --since -10min   # compositor log up to the freeze
#   journalctl -k                 -b -1 --since -10min   # kernel: SysRq/hung-task dumps, Xid, OOM
{
  nixos =
    { ... }:
    let
      # Stable NixOS symlink to the current system's nvidia-smi (host has
      # hardware.nvidia enabled). Resolved at runtime, so it tracks driver bumps.
      nvidiaSmi = "/run/current-system/sw/bin/nvidia-smi";
    in
    {
      # --- PREVENTION -------------------------------------------------------

      # earlyoom: userspace OOM watchdog. It fires only when free RAM *and* free
      # swap are BOTH under threshold, so normal heavy use is untouched; when they
      # are, it kills the biggest match before the kernel's own late, thrash-
      # inducing OOM killer ever runs.
      #  --prefer: the Rust toolchain — regenerable, no unsaved state (rust-analyzer
      #            just reindexes, a build just re-runs), and the actual memory hog
      #            the kernel's killer kept ignoring (it took a chrome tab instead).
      #  --avoid:  the compositor, the SSH lifeline, and the session/service manager
      #            — the processes whose death takes the whole session with them.
      services.earlyoom = {
        enable = true;
        freeMemThreshold = 5; # SIGTERM under 5% free RAM (SIGKILL under ~2.5%, the default half)
        freeSwapThreshold = 10; # ...and under 10% free swap; both must hold before it acts
        extraArgs = [
          "--prefer"
          "^(rust-analyzer|rustc|rust-lld|cargo)$"
          "--avoid"
          "^(Hyprland|sshd|systemd|greetd)$"
        ];
      };

      # zram: compressed swap that lives in RAM, at a higher priority than the disk
      # partition so it fills first (the 8G disk swap stays as low-priority overflow;
      # no hibernation is configured, so nothing depends on it). Memory pressure
      # becomes a brief CPU-cost slowdown instead of a disk-seek lockup, buying
      # headroom before earlyoom has to fire. memoryPercent is a cap, not a
      # reservation — RAM is consumed only as pages are actually swapped in.
      zramSwap = {
        enable = true;
        memoryPercent = 50; # up to ~32G of 64G may back zram (zstd-compressed)
        priority = 100; # higher than the disk swap partition so zram is used first
      };

      # --- DIAGNOSIS --------------------------------------------------------

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
