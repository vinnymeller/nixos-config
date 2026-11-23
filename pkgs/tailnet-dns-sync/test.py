"""Behaviour test for tailnet-dns-sync against a fake Cloudflare API.

Usage: python3 -I test.py <path to tailnet-dns-sync>
Each case seeds DNS records and a `tailscale status --json` fixture, runs the
script, and checks the exit code, the final records, and the writes it made.
"""

import json
import subprocess
import sys
import tempfile
import threading
import urllib.parse
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

SCRIPT = sys.argv[1]
ZONE = "vinnix.net"
ZONE_ID = "zone123"
TOKEN = "test-token"
TAG = "tag:shared"
MARKER = "managed-by: nixdots tailnet-dns-sync"


class FakeCloudflare:
    def __init__(self):
        self.records = {}
        self.writes = []
        self.next_id = 1

    def reset(self, records):
        self.records = {}
        self.writes = []
        self.next_id = 1
        for r in records:
            self.add(dict(r))

    def add(self, record):
        record.setdefault("id", f"rec{self.next_id}")
        self.next_id += 1
        record.setdefault("proxied", False)
        record.setdefault("ttl", 1)
        record.setdefault("comment", None)
        self.records[record["id"]] = record
        return record


FAKE = FakeCloudflare()


class Handler(BaseHTTPRequestHandler):
    def log_message(self, format, *args):
        pass

    def reply(self, code, payload):
        body = json.dumps(payload).encode()
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def ok(self, result, info=None):
        payload = {"success": True, "errors": [], "result": result}
        if info:
            payload["result_info"] = info
        self.reply(200, payload)

    def body(self):
        length = int(self.headers.get("Content-Length") or 0)
        return json.loads(self.rfile.read(length) or b"{}")

    def route(self, method):
        if self.headers.get("Authorization") != "Bearer " + TOKEN:
            return self.reply(403, {"success": False, "errors": [{"message": "bad token"}]})
        url = urllib.parse.urlparse(self.path)
        query = dict(urllib.parse.parse_qsl(url.query))
        parts = url.path.strip("/").split("/")
        if parts == ["zones"] and method == "GET":
            zones = [{"id": ZONE_ID, "name": ZONE}] if query.get("name") == ZONE else []
            return self.ok(zones, {"total_pages": 1})
        if parts[:3] != ["zones", ZONE_ID, "dns_records"]:
            return self.reply(404, {"success": False, "errors": [{"message": "no route"}]})
        if len(parts) == 3 and method == "GET":
            rows = list(FAKE.records.values())
            if "name.exact" in query:
                rows = [r for r in rows if r["name"] == query["name.exact"]]
            if "comment.exact" in query:
                rows = [r for r in rows if (r["comment"] or "").lower() == query["comment.exact"].lower()]
            # Paginate in pages of 1 to exercise the client's paging loop.
            page = int(query.get("page", 1))
            return self.ok(rows[page - 1:page], {"total_pages": max(len(rows), 1)})
        if len(parts) == 3 and method == "POST":
            record = FAKE.add(self.body())
            FAKE.writes.append(("POST", record["name"]))
            return self.ok(record)
        if len(parts) == 4 and parts[3] in FAKE.records:
            record = FAKE.records[parts[3]]
            if method == "PATCH":
                record.update(self.body())
                FAKE.writes.append(("PATCH", record["name"]))
                return self.ok(record)
            if method == "DELETE":
                del FAKE.records[parts[3]]
                FAKE.writes.append(("DELETE", record["name"]))
                return self.ok({"id": parts[3]})
        return self.reply(404, {"success": False, "errors": [{"message": "no route"}]})

    def do_GET(self):
        self.route("GET")

    def do_POST(self):
        self.route("POST")

    def do_PATCH(self):
        self.route("PATCH")

    def do_DELETE(self):
        self.route("DELETE")


SERVER = ThreadingHTTPServer(("127.0.0.1", 0), Handler)
threading.Thread(target=SERVER.serve_forever, daemon=True).start()
API = f"http://127.0.0.1:{SERVER.server_address[1]}"


def node(host, ip, tags=(TAG,), online=True):
    return {"HostName": host, "Tags": list(tags), "Online": online,
            "TailscaleIPs": [ip, "fd7a:115c:a1e0::1"]}


JELLYFIN = node("jellyfin", "100.106.77.10")
SEERR = node("seerr", "100.91.38.26")
WILDCARD = {"type": "A", "name": f"*.{ZONE}", "content": "100.84.174.23"}
UNRELATED = {"type": "A", "name": f"foo.{ZONE}", "content": "1.2.3.4"}


def managed(name, ip, **extra):
    return dict({"type": "A", "name": f"{name}.{ZONE}", "content": ip,
                 "proxied": False, "ttl": 60, "comment": MARKER}, **extra)


def run(peers, records, names, self_node=None):
    FAKE.reset(records)
    status = {"Self": self_node or node("vinnix", "100.84.174.23", tags=()),
              "Peer": {f"key{i}": p for i, p in enumerate(peers)}}
    with tempfile.NamedTemporaryFile("w", suffix=".json") as f:
        json.dump(status, f)
        f.flush()
        cmd = [SCRIPT, "--zone", ZONE, "--tag", TAG, "--status-file", f.name, "--api-base", API]
        for n in names:
            cmd += ["--name", n]
        proc = subprocess.run(cmd, capture_output=True, text=True,
                              env={"CF_API_TOKEN": TOKEN, "PATH": "/usr/bin:/bin"})
    return proc


def a_records(name):
    return [r for r in FAKE.records.values() if r["name"] == f"{name}.{ZONE}" and r["type"] == "A"]


FAILURES = []


def check(case, cond, detail):
    if not cond:
        FAILURES.append(f"[{case}] {detail}")


def untouched(case, *originals):
    for orig in originals:
        match = [r for r in FAKE.records.values() if r["name"] == orig["name"]]
        check(case, len(match) == 1 and match[0]["content"] == orig["content"]
              and match[0]["comment"] == orig.get("comment"),
              f"{orig['name']} changed: {match}")
    for method, name in FAKE.writes:
        check(case, name not in {o["name"] for o in originals}, f"wrote {method} {name}")


def expect(case, proc, code):
    check(case, proc.returncode == code,
          f"exit {proc.returncode}, wanted {code}; stderr:\n{proc.stderr}")


# 1. Missing record -> created with node IPv4, proxied=false, ttl=60, marker.
p = run([JELLYFIN, SEERR], [WILDCARD, UNRELATED], ["jellyfin", "seerr"])
expect(1, p, 0)
for name, ip in (("jellyfin", "100.106.77.10"), ("seerr", "100.91.38.26")):
    recs = a_records(name)
    check(1, len(recs) == 1, f"{name}: {recs}")
    if recs:
        r = recs[0]
        check(1, (r["content"], r["proxied"], r["ttl"], r["comment"]) == (ip, False, 60, MARKER), f"{name}: {r}")
# 5. Wildcard and unrelated records untouched.
untouched(1, WILDCARD, UNRELATED)

# 2. Stale IP -> updated in place (same record id).
p = run([JELLYFIN], [WILDCARD, managed("jellyfin", "100.1.1.1", id="keepme")], ["jellyfin"])
expect(2, p, 0)
recs = a_records("jellyfin")
check(2, len(recs) == 1 and recs[0]["id"] == "keepme" and recs[0]["content"] == "100.106.77.10", f"{recs}")
check(2, FAKE.writes == [("PATCH", f"jellyfin.{ZONE}")], f"writes {FAKE.writes}")
untouched(2, WILDCARD)

# 3. Already correct -> zero writes.
p = run([JELLYFIN, SEERR], [WILDCARD, managed("jellyfin", "100.106.77.10"), managed("seerr", "100.91.38.26")],
        ["jellyfin", "seerr"])
expect(3, p, 0)
check(3, FAKE.writes == [], f"writes {FAKE.writes}")

# 4. Marker record for a name no longer shared -> deleted; others untouched.
p = run([JELLYFIN], [WILDCARD, UNRELATED, managed("jellyfin", "100.106.77.10"), managed("grimmory", "100.93.143.73")],
        ["jellyfin"])
expect(4, p, 0)
check(4, a_records("grimmory") == [], "grimmory record not deleted")
check(4, FAKE.writes == [("DELETE", f"grimmory.{ZONE}")], f"writes {FAKE.writes}")
untouched(4, WILDCARD, UNRELATED)

# 4b. Nothing shared any more -> every marker record deleted, nothing else.
p = run([], [WILDCARD, UNRELATED, managed("jellyfin", "100.106.77.10")], [])
expect("4b", p, 0)
check("4b", a_records("jellyfin") == [], "jellyfin record not deleted")
untouched("4b", WILDCARD, UNRELATED)

# 6. Hand-made unmarked record for a desired name -> updated and marked.
p = run([JELLYFIN], [WILDCARD, {"type": "A", "name": f"jellyfin.{ZONE}", "content": "100.84.174.23",
                                "proxied": True, "ttl": 300, "id": "manual"}], ["jellyfin"])
expect(6, p, 0)
recs = a_records("jellyfin")
check(6, len(recs) == 1 and recs[0]["id"] == "manual" and recs[0]["content"] == "100.106.77.10"
      and recs[0]["comment"] == MARKER and recs[0]["proxied"] is False, f"{recs}")

# 7. Desired node absent -> its record untouched, others synced, non-zero exit.
stale_seerr = managed("seerr", "100.91.38.26")
p = run([JELLYFIN], [WILDCARD, stale_seerr], ["jellyfin", "seerr"])
expect(7, p, 1)
check(7, len(a_records("jellyfin")) == 1, "jellyfin not created")
untouched(7, WILDCARD, stale_seerr)

# 8. Spoofed untagged HostName alongside the tagged node -> tagged one wins.
spoof = node("jellyfin", "100.118.32.18", tags=())
p = run([spoof, JELLYFIN], [WILDCARD], ["jellyfin"])
expect(8, p, 0)
recs = a_records("jellyfin")
check(8, len(recs) == 1 and recs[0]["content"] == "100.106.77.10", f"{recs}")

# 8b. Only an untagged device with that name -> no change, non-zero exit.
p = run([spoof], [WILDCARD], ["jellyfin"])
expect("8b", p, 1)
check("8b", a_records("jellyfin") == [] and FAKE.writes == [], f"writes {FAKE.writes}")

# 9. The only tagged match is offline -> still used.
p = run([node("jellyfin", "100.106.77.10", online=False)], [WILDCARD], ["jellyfin"])
expect(9, p, 0)
check(9, [r["content"] for r in a_records("jellyfin")] == ["100.106.77.10"], f"{a_records('jellyfin')}")

# 10. Two tagged matches, exactly one online -> the online one.
old = node("jellyfin", "100.64.0.99", online=False)
p = run([old, JELLYFIN], [WILDCARD], ["jellyfin"])
expect(10, p, 0)
check(10, [r["content"] for r in a_records("jellyfin")] == ["100.106.77.10"], f"{a_records('jellyfin')}")

# 10b. Two tagged matches, both online -> no change, non-zero exit.
p = run([node("jellyfin", "100.64.0.99"), JELLYFIN], [WILDCARD], ["jellyfin"])
expect("10b", p, 1)
check("10b", FAKE.writes == [], f"writes {FAKE.writes}")

# 11. Two A records, or a CNAME, at a desired name -> no change, non-zero exit.
dup1 = {"type": "A", "name": f"jellyfin.{ZONE}", "content": "1.1.1.1"}
dup2 = {"type": "A", "name": f"jellyfin.{ZONE}", "content": "2.2.2.2"}
p = run([JELLYFIN], [WILDCARD, dup1, dup2], ["jellyfin"])
expect(11, p, 1)
check(11, FAKE.writes == [], f"writes {FAKE.writes}")
cname = {"type": "CNAME", "name": f"seerr.{ZONE}", "content": "elsewhere.example"}
p = run([SEERR], [WILDCARD, cname], ["seerr"])
expect("11b", p, 1)
check("11b", FAKE.writes == [], f"writes {FAKE.writes}")

# 12. Bad token -> exit 2, nothing written.
FAKE.reset([WILDCARD])
with tempfile.NamedTemporaryFile("w", suffix=".json") as f:
    json.dump({"Peer": {"k": JELLYFIN}}, f)
    f.flush()
    p = subprocess.run([SCRIPT, "--zone", ZONE, "--tag", TAG, "--status-file", f.name, "--api-base", API,
                        "--name", "jellyfin"], capture_output=True, text=True,
                       env={"CF_API_TOKEN": "wrong", "PATH": "/usr/bin:/bin"})
expect(12, p, 2)
check(12, FAKE.writes == [], f"writes {FAKE.writes}")

SERVER.shutdown()
if FAILURES:
    print("FAIL\n" + "\n".join(FAILURES))
    sys.exit(1)
print("tailnet-dns-sync: all cases passed")
