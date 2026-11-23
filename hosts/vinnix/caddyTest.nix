{ pkgs, nixos }:
# Checks vinnix's generated Caddy config: the shared UIs (jellyfin, seerr) are
# served only from their own tailnet nodes, every other UI only from the host,
# no *.ts.net sites exist, and the DNS sync and firewall agree with it.
#   nix build .#checks.x86_64-linux.vinnix-caddy
let
  cfg = nixos.config;
  facts = pkgs.writeText "vinnix-facts.json" (
    builtins.toJSON {
      dnsSyncExec = cfg.systemd.services.tailnet-dns-sync.serviceConfig.ExecStart;
      udpPorts = cfg.networking.firewall.allowedUDPPorts;
    }
  );
in
pkgs.runCommand "vinnix-caddy-test"
  {
    nativeBuildInputs = [
      cfg.services.caddy.package
      pkgs.jq
    ];
  }
  ''
    export HOME=$TMPDIR
    fail() { echo "FAIL: $*" >&2; exit 1; }

    caddy adapt --adapter caddyfile --config ${cfg.services.caddy.configFile} > caddy.json

    # Sorted listen addresses of every server that routes host $1.
    listen_of() {
      jq -r --arg h "$1" '
        [.apps.http.servers[]
         | select([.routes[]?.match[]?.host[]?] | index($h))
         | .listen[]] | sort | join(",")' caddy.json
    }

    for name in jellyfin seerr; do
      got=$(listen_of "$name.vinnix.net")
      [ "$got" = "tailscale/$name:443" ] || fail "$name.vinnix.net listens on '$got', want only its node"
    done
    for name in immich paperless grimmory sonarr radarr prowlarr qbittorrent; do
      got=$(listen_of "$name.vinnix.net")
      [ "$got" = ":443" ] || fail "$name.vinnix.net listens on '$got', want only the host"
    done

    jq -e '[.. | strings | select(test("ts\\.net"))] == []' caddy.json >/dev/null \
      || fail "a *.ts.net name is still configured"
    jq -e '.apps.tailscale.tags == ["tag:shared"]' caddy.json >/dev/null \
      || fail "tailscale app tags: $(jq -c .apps.tailscale.tags caddy.json)"
    jq -e '.apps.tailscale.nodes == {"jellyfin": {"port": 41642}, "seerr": {"port": 41643}}' caddy.json >/dev/null \
      || fail "tailscale nodes: $(jq -c .apps.tailscale.nodes caddy.json)"

    names=$(jq -r .dnsSyncExec ${facts} | grep -o -- '--name [a-z]*' | cut -d' ' -f2 | sort | tr '\n' ' ')
    [ "$names" = "jellyfin seerr " ] || fail "tailnet-dns-sync names: '$names'"
    jq -e '.udpPorts | index(41642) and index(41643)' ${facts} >/dev/null \
      || fail "firewall UDP ports: $(jq -c .udpPorts ${facts})"

    echo "vinnix-caddy: all checks passed"
    touch $out
  ''
