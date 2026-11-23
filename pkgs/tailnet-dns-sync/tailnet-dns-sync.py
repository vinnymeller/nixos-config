"""Point each shared web UI's DNS name at its tailnet node.

A shared service is served only from its own tailnet node (Caddy's tsnet
node), so <name>.<zone> must resolve to that node instead of falling through
to the *.<zone> wildcard, which points at the host. This keeps one Cloudflare
A record per shared name in sync, and removes records it created for names
that are no longer shared.

Safety rules:
  - A node is trusted only if it carries --tag. HostName is chosen by the
    client (a friend could call a laptop "jellyfin"); only an admin can tag.
  - A node that can't be found never causes a record to change or vanish:
    pointing the name anywhere else (e.g. back at the host) would break it.
  - Only records carrying MARKER in their comment are ever deleted; records
    are only created/updated for the declared names.

Exit status: 0 if every name is in sync, 1 if some name was skipped (logged),
2 on a Cloudflare/tailscale error.
"""

import argparse
import json
import os
import subprocess
import sys
import urllib.error
import urllib.parse
import urllib.request

MARKER = "managed-by: nixdots tailnet-dns-sync"
TTL = 60
DEFAULT_API = "https://api.cloudflare.com/client/v4"


def log(msg):
    print(msg, file=sys.stderr, flush=True)


class CloudflareError(Exception):
    pass


class Cloudflare:
    def __init__(self, base, token):
        self.base = base.rstrip("/")
        self.token = token

    def request(self, method, path, query=None, body=None):
        url = self.base + path
        if query:
            url += "?" + urllib.parse.urlencode(query)
        data = None if body is None else json.dumps(body).encode()
        req = urllib.request.Request(
            url,
            data=data,
            method=method,
            headers={
                "Authorization": "Bearer " + self.token,
                "Content-Type": "application/json",
            },
        )
        try:
            with urllib.request.urlopen(req, timeout=30) as resp:
                payload = json.load(resp)
        except urllib.error.HTTPError as err:
            detail = err.read().decode(errors="replace")[:500]
            raise CloudflareError(f"{method} {path}: HTTP {err.code}: {detail}") from None
        except urllib.error.URLError as err:
            raise CloudflareError(f"{method} {path}: {err.reason}") from None
        if not payload.get("success", False):
            raise CloudflareError(f"{method} {path}: {payload.get('errors')}")
        return payload

    def list(self, path, query):
        results, page = [], 1
        while True:
            payload = self.request("GET", path, dict(query, page=page, per_page=100))
            results.extend(payload["result"])
            info = payload.get("result_info") or {}
            if page >= info.get("total_pages", 1):
                return results
            page += 1


def load_peers(args):
    if args.status_file:
        with open(args.status_file) as f:
            status = json.load(f)
    else:
        out = subprocess.run(
            [args.tailscale, "status", "--json"],
            check=True,
            capture_output=True,
            text=True,
        ).stdout
        status = json.loads(out)
    peers = list((status.get("Peer") or {}).values())
    if status.get("Self"):
        peers.append(status["Self"])
    return peers


def find_node_ip(peers, name, tag):
    """Return (ipv4, None) for the trusted node called `name`, or (None, why)."""
    matches = [
        p for p in peers if p.get("HostName") == name and tag in (p.get("Tags") or [])
    ]
    if not matches:
        untagged = [p for p in peers if p.get("HostName") == name]
        hint = f" ({len(untagged)} untagged device(s) use that name)" if untagged else ""
        return None, f"no node named {name!r} carries {tag}{hint}"
    if len(matches) > 1:
        online = [p for p in matches if p.get("Online")]
        if len(online) != 1:
            return None, (
                f"{len(matches)} nodes named {name!r} carry {tag} and "
                f"{len(online)} are online; refusing to guess"
            )
        matches = online
    ipv4 = [ip for ip in matches[0].get("TailscaleIPs") or [] if "." in ip]
    if not ipv4:
        return None, f"node {name!r} has no IPv4 address"
    return ipv4[0], None


def sync(cf, zone, names, peers, tag):
    """Reconcile records; return True if every name ended up in sync."""
    zones = cf.list("/zones", {"name": zone})
    if len(zones) != 1:
        raise CloudflareError(f"expected one zone named {zone!r}, got {len(zones)}")
    records_path = f"/zones/{zones[0]['id']}/dns_records"

    ok = True
    desired = {f"{name}.{zone}": name for name in names}
    for fqdn, name in desired.items():
        ip, why = find_node_ip(peers, name, tag)
        if ip is None:
            log(f"{fqdn}: {why}; leaving DNS unchanged")
            ok = False
            continue

        existing = cf.list(records_path, {"name.exact": fqdn})
        a_records = [r for r in existing if r["type"] == "A"]
        cnames = [r for r in existing if r["type"] == "CNAME"]
        if cnames or len(a_records) > 1:
            log(
                f"{fqdn}: found {len(a_records)} A and {len(cnames)} CNAME "
                "record(s); fix them by hand, leaving DNS unchanged"
            )
            ok = False
            continue

        want = {
            "type": "A",
            "name": fqdn,
            "content": ip,
            "proxied": False,
            "ttl": TTL,
            "comment": MARKER,
        }
        if not a_records:
            cf.request("POST", records_path, body=want)
            log(f"{fqdn}: created A {ip}")
            continue

        record = a_records[0]
        current = {k: record.get(k) for k in ("content", "proxied", "ttl", "comment")}
        if current == {k: want[k] for k in current}:
            continue
        if record.get("comment") != MARKER:
            log(f"{fqdn}: taking over existing record (was {record.get('content')})")
        cf.request("PATCH", f"{records_path}/{record['id']}", body=want)
        log(f"{fqdn}: updated A {record.get('content')} -> {ip}")

    for record in cf.list(records_path, {"comment.exact": MARKER}):
        if record.get("comment") == MARKER and record["name"] not in desired:
            cf.request("DELETE", f"{records_path}/{record['id']}")
            log(f"{record['name']}: no longer shared, deleted {record['type']} {record.get('content')}")

    return ok


def read_token():
    cred_dir = os.environ.get("CREDENTIALS_DIRECTORY")
    if cred_dir:
        with open(os.path.join(cred_dir, "cf-token")) as f:
            return f.read().strip()
    token = os.environ.get("CF_API_TOKEN", "").strip()
    if not token:
        raise SystemExit("tailnet-dns-sync: no cf-token credential and CF_API_TOKEN unset")
    return token


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--zone", required=True, help="DNS zone, e.g. vinnix.net")
    parser.add_argument("--tag", required=True, help="ACL tag shared nodes carry")
    parser.add_argument("--name", action="append", default=[], help="shared service (repeatable)")
    source = parser.add_mutually_exclusive_group()
    source.add_argument("--tailscale", default="tailscale", help="tailscale CLI to query")
    source.add_argument("--status-file", help="read `tailscale status --json` output from a file")
    parser.add_argument("--api-base", default=DEFAULT_API, help="Cloudflare API base URL")
    args = parser.parse_args()

    names = sorted(set(args.name))
    for name in names:
        if not name or "." in name:
            parser.error(f"--name must be a single DNS label, got {name!r}")

    try:
        peers = load_peers(args) if names else []
        cf = Cloudflare(args.api_base, read_token())
        ok = sync(cf, args.zone, names, peers, args.tag)
    except (CloudflareError, subprocess.CalledProcessError, OSError, ValueError) as err:
        log(f"tailnet-dns-sync: {err}")
        return 2
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
