{
  options =
    {
      lib,
      ...
    }:
    {
      dataDir = lib.mkOption {
        type = lib.types.str;
        default = "/data/valheim";
        description = "Base directory for Valheim server data.";
      };

      secretFile = lib.mkOption {
        type = lib.types.path;
        description = "Age-encrypted .env containing SERVER_PASS (min. 5 characters, or the server refuses to start).";
      };

      serverName = lib.mkOption {
        type = lib.types.str;
        default = "Vinnheim";
        description = "Name shown in the server browser.";
      };

      worldName = lib.mkOption {
        type = lib.types.str;
        default = "Pirate68";
        description = ''
          Name of the world directory inside <dataDir>/config/worlds_local.

          Valheim has NO -seed launch argument: the seed is written into the
          world's .fwl at creation time and cannot be set server-side. To run a
          specific seed you generate the world once in the desktop client and
          copy the folder in. See the seed note in the nixos block below.
        '';
      };

      port = lib.mkOption {
        type = lib.types.port;
        default = 2456;
        description = ''
          UDP start port. The server binds port and port+1, plus port+2 for the
          crossplay (PlayFab) backend.
        '';
      };

      public = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          List the server in the public browser. Off by default: friends join
          with the crossplay join code, which is issued either way.
        '';
      };
    };

  nixos =
    { cfg, lib, ... }:
    let
      # The image wants two volumes with very different value:
      #   config -> worlds, backups, admin/ban/permit lists, mod configs  (irreplaceable)
      #   server -> SteamCMD cache + the ~1GB server install              (re-downloadable)
      # Splitting them keeps the restic job pointed only at what matters.
      configDir = "${cfg.dataDir}/config";
      serverDir = "${cfg.dataDir}/server";

      # World modifiers are launch arguments, not world-creation settings, so
      # these can be retuned later with a rebuild + restart.
      #
      # -preset Normal FIRST, deliberately. A world created in the desktop
      # client carries its own stored modifiers, and those were winning over
      # bare -modifier flags: the server advertised Resource rate x3, Passive
      # enemies and unrestricted Portals -- a permissive preset none of these
      # four flags ask for. Per Iron Gate's guide a preset "establishes a
      # baseline and overwrites previous world modifiers", with -modifier
      # applied after it, so the preset is the reset lever that clears whatever
      # the world shipped with. Order matters: preset first, modifiers after.
      #
      #   Combat hard          -> player dmg 85%, enemy dmg 150%, enemy speed/size
      #                           110%, star-enemy rate 120%
      #   DeathPenalty veryeasy-> equipment and inventory both drop, but skill
      #                           loss is 1% instead of the default 5%
      #   Resources muchmore   -> 2x drops from mobs and lootable objects
      #                           (resourcerate 200). Does not affect fish,
      #                           trophies or boss drops. `most` is 3x, which
      #                           felt like too much.
      #   Raids more           -> raid interval 60min at 33.3% chance
      #                           (default: 100min at 20%)
      #   Portals              -> omitted, i.e. stock behaviour (no ore/metal)
      #   setkey playerevents  -> raids scale to each player's own boss
      #                           progress rather than the world's, so friends
      #                           joining late do not inherit endgame raids
      #
      # These MUST stay in sync with the modifier block stored inside the world
      # itself (visible as plain strings in _main.N.fwl2). A world created or
      # edited in the desktop client carries its own settings, and -preset
      # overwrites them wholesale on start -- so a mismatch here silently
      # rewrites choices made in the client. Current world agrees with the
      # below: combat_hard:deathpenalty_veryeasy:resources_muchmore:raids_more
      # :portals_default plus playerevents.
      serverArgs = lib.concatStringsSep " " [
        "-preset Normal"
        "-modifier Combat hard"
        "-modifier DeathPenalty veryeasy"
        "-modifier Resources muchmore"
        "-modifier Raids more"
        "-setkey playerevents"
      ];
    in
    {
      mine.services.dockerCompose.stacks.valheim = {
        # Pulls a newer *image*. The container updates the Valheim server
        # itself on its own schedule (UPDATE_CRON below) since it runs
        # SteamCMD at startup rather than pinning a build.
        autoUpdate.enable = true;

        # NOTE: tailscale.serviceName is deliberately unset (its default is
        # null). The docker-compose module selects stacks for the Caddy +
        # tsnet proxy with `filterAttrs (_: s: s.tailscale.serviceName != null)`,
        # so leaving it out is what keeps Caddy's hands off this stack. Valheim
        # is raw UDP and there is nothing for an HTTPS reverse proxy to do here.

        # Every port on this stack is meant to be reachable off-host, so opt out
        # of the module's default loopback binding wholesale rather than
        # prefixing each mapping. Nothing here should ever be 127.0.0.1-only,
        # including 2458 if mods get added later.
        #
        # Crossplay relays through PlayFab, so none of this needs a router
        # port-forward -- publishing only buys LAN clients a direct, un-relayed
        # path and leaves the door open if we ever do forward.
        publishLoopbackOnly = false;

        # First run pulls the image and then downloads the server via SteamCMD
        # inside the container. The image ships no HEALTHCHECK, so `up --wait`
        # returns once the container is running, but the image pull itself can
        # be slow on a cold cache.
        timeoutStartSec = "20m";

        # The container asks for a 2m stop_grace_period to flush the world, and
        # the module's default timeoutStopSec is exactly 120s -- too tight to
        # race against. Give systemd room to let the save finish.
        timeoutStopSec = "3m";

        agenix.envFile = {
          file = cfg.secretFile;
          services = [ "valheim" ];
        };

        backup = {
          enable = true;
          paths = [ configDir ];
          # The container writes its own hourly zips into config/backups. Those
          # are a local convenience; restic should capture the live world files
          # instead, which dedupe far better than a churn of zip archives.
          exclude = [ "${configDir}/backups" ];
        };

        # Left root-owned (the module default), matching the image's default
        # PUID/PGID of 0. Running the server non-root is a documented footgun on
        # this image: 1.0 world conversion strips the execute bit from the new
        # per-world directories, and the server then logs
        # UnauthorizedAccessException and keeps running with NO world loaded --
        # a container that looks perfectly healthy while serving nothing.
        storage.directories = {
          "${cfg.dataDir}" = { };
          "${configDir}" = { };
          "${configDir}/worlds_local" = { };
          "${serverDir}" = { };
        };

        compose = {
          services.valheim = {
            image = "ghcr.io/community-valheim-tools/valheim-server:latest";
            container_name = "valheim";
            restart = "unless-stopped";

            # Optional per the image docs: lets the Steam library Valheim uses
            # hand itself more CPU cycles. Cheap to grant, and this box has the
            # headroom.
            cap_add = [ "sys_nice" ];
            # Matches the image's own compose example. The server needs time to
            # flush the world on shutdown -- see timeoutStopSec above, which is
            # set wider so systemd does not guillotine the save.
            stop_grace_period = "2m";

            ports = [
              "${toString cfg.port}:${toString cfg.port}/udp"
              "${toString (cfg.port + 1)}:${toString (cfg.port + 1)}/udp"
              # Crossplay backend. Also the port mods want if BepInEx ever
              # lands here and a plugin uses RPC.
              "${toString (cfg.port + 2)}:${toString (cfg.port + 2)}/udp"
            ];

            volumes = [
              "${configDir}:/config"
              "${serverDir}:/opt/valheim"
            ];

            environment = {
              SERVER_NAME = cfg.serverName;
              SERVER_PORT = toString cfg.port;
              WORLD_NAME = cfg.worldName;
              SERVER_PUBLIC = lib.boolToString cfg.public;
              # SERVER_PASS comes from agenix.envFile above.

              CROSSPLAY = "true";

              SERVER_ARGS = serverArgs;

              # Default is */15 * * * * with UPDATE_IF_IDLE=true, but player
              # detection is broken under crossplay (upstream issue #815, open):
              # the idle check polls the Steam query port, which PlayFab
              # bypasses, so the server reports "nobody connected" and restarts
              # into an active session. Pinning updates and the daily restart to
              # an early-morning window makes that misfire harmless. IF_IDLE
              # stays on as a best-effort second line of defence.
              UPDATE_CRON = "0 6 * * *";
              UPDATE_IF_IDLE = "true";
              RESTART_CRON = "30 6 * * *";
              RESTART_IF_IDLE = "true";

              # Container-side backups, independent of and complementary to the
              # restic job: these are cheap local rollback points.
              BACKUPS = "true";
              BACKUPS_CRON = "5 * * * *";
              BACKUPS_MAX_AGE = "14";
              BACKUPS_ZIP = "true";

              # No whitelist yet, on purpose. permittedlist.txt is all-or-
              # nothing -- per Iron Gate, "adding a person on the permitted list
              # will ban everyone else from the server" -- and 1.0 changed the
              # ID format to [Platform]_[UserID] (or the F2-panel form with
              # V_/X_/S_/A_/N_ prefixes). Get everyone connected once, collect
              # their IDs from the in-game F2 panel, then set PERMITTEDLIST_IDS
              # here. Password-only is a reasonable interim given the server is
              # unlisted and reachable only by join code.
              # PERMITTEDLIST_IDS = "";
              # ADMINLIST_IDS = "";
            };
          };
        };
      };

      # ── Seed / world provisioning ─────────────────────────────────────
      # Valheim has no -seed argument; the seed is written into the world's
      # .fwl2 at generation and is fixed from then on. A world therefore has to
      # be made in the desktop client and copied in.
      #
      # Two gotchas found the hard way on this machine:
      #
      #   1. The world NAME and the SEED are independent. WORLD_NAME above
      #      matches the *directory* name only; the seed lives inside the
      #      world data. Name and seed happen to both be "Pirate68" here.
      #
      #   2. Steam Cloud saves (on by default) decide WHERE the world lives.
      #      A cloud world leaves only cacheMinimap* files in worlds_local and
      #      keeps the real .fwl2/.db2/chunks under
      #        ~/.local/share/Steam/userdata/<steamid>/892970/remote/worlds/<name>/
      #      Either copy from there, or flip the world to local first via
      #      World Select -> Manage Saves -> Worlds -> Move to Local, which
      #      relocates the full set into
      #        ~/.config/unity3d/IronGate/Valheim/worlds_local/<name>/
      #      (this is what Pirate68 was provisioned from). A complete world is
      #      _main.N.fwl2 + _main.N.db2 + _main.N.chunks + _main.N.ok + chunks;
      #      if you only see cacheMinimap* files, you are in the wrong place.
      #
      # To (re)provision a world:
      #   1. Client -> New World, set name and seed, load in, play 1-2 min,
      #      then quit to desktop so the save flushes.
      #   2. sudo systemctl stop docker-compose-valheim
      #   3. sudo rm -rf /data/valheim/config/worlds_local/<name>   # if present
      #   4. sudo cp -r <source world dir> /data/valheim/config/worlds_local/
      #      sudo chown -R root:root /data/valheim/config/worlds_local/<name>
      #   5. Point worldName at <name>, rebuild, start the stack.
      #
      # The server starts BEFORE you get a chance to do any of this: if no
      # world exists under WORLD_NAME it silently generates a random-seed one
      # and looks perfectly healthy doing it. Stop the stack before the first
      # start, or delete what it made and redo the copy.
    };
}
