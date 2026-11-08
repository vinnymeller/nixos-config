{ pkgs }:
# Behavior test for claude-context-archive against fixture transcripts laid out
# the way Claude Code writes them (see contextArchiveTest.sh).
#   nix build .#checks.<system>.claude-context-archive
pkgs.runCommand "claude-context-archive-test"
  {
    nativeBuildInputs = with pkgs; [
      claude-context-archive
      coreutils
      gawk
      git
      gnugrep
      gnused
      jq
      procps
    ];
  }
  ''
    bash ${./contextArchiveTest.sh}
    touch $out
  ''
