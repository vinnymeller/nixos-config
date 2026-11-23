{ pkgs }:
# Behaviour test for tailnet-dns-sync against a fake Cloudflare API (see test.py).
#   nix build .#checks.<system>.tailnet-dns-sync
let
  tailnet-dns-sync = pkgs.callPackage ./. { };
in
pkgs.runCommand "tailnet-dns-sync-test" { nativeBuildInputs = [ pkgs.python3 ]; } ''
  python3 -I ${./test.py} ${tailnet-dns-sync}/bin/tailnet-dns-sync
  touch $out
''
