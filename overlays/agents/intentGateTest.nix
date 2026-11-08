{ pkgs }:
# Behavior test for claude-intent-gate with a stub judge (see intentGateTest.sh).
#   nix build .#checks.<system>.claude-intent-gate
pkgs.runCommand "claude-intent-gate-test"
  {
    nativeBuildInputs = with pkgs; [
      claude-intent-gate
      claude-context-archive
      coreutils
      git
      gnugrep
      gnused
      jq
    ];
  }
  ''
    bash ${./intentGateTest.sh}
    touch $out
  ''
