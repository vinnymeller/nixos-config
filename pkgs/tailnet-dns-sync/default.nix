{ writers }:
# Points <name>.<zone> at each shared web UI's tailnet node in Cloudflare DNS.
# Used by modules/nixos/docker-service.nix; behaviour test in ./test.nix
# (flake check `tailnet-dns-sync`).
writers.writePython3Bin "tailnet-dns-sync" { flakeIgnore = [ "E501" ]; } (
  builtins.readFile ./tailnet-dns-sync.py
)
