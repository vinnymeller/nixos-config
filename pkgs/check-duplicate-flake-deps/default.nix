{ pkgs, ... }:

with pkgs;

stdenv.mkDerivation {
  name = "check-duplicate-flake-deps";
  propagatedBuildInputs = [
    python3
  ];
  dontUnpack = true;
  installPhase = "install -Dm755 ${../../scripts/check-duplicate-flake-deps.py} $out/bin/check-duplicate-flake-deps";
}
