{
  pkgs,
  contextArchive,
  # The unwrapped Claude Code package: the judge must not load the wrapper's
  # hooks, plugins or MCP servers.
  judgeClaude,
  judgeModel ? "claude-sonnet-5-5",
}:
# Hook gates that keep agents deciding instead of asking, and plans complete
# before the user sees them. Each mode reads a hook payload on stdin:
#
#   claude-intent-gate ask    PreToolUse(AskUserQuestion): a question the user's
#                             words already answer, or one the agent may decide
#                             itself, goes back to the agent instead of the user.
#   claude-intent-gate stop   Stop: a turn that ends by asking the user something
#                             the agent may decide is sent back to work.
#   claude-intent-gate plan   PreToolUse(ExitPlanMode): a plan that misses what the
#                             user asked for, leaves behavior undefined, or names
#                             no test goes back for revision (at most twice).
#
# The verdict comes from a short headless Claude run (the judge) that sees the
# policy, the user's own messages (`claude-context-archive intent`), the agent's
# latest words, and the item under judgment. Everything around it is
# deterministic, and every failure FAILS OPEN: a judge error, timeout or odd
# reply lets the question or plan through and logs a gate-error event, so a
# broken gate can never block work.
#
# Environment:
#   CLAUDE_INTENT_GATES=0          disable all gates (kill switch)
#   CLAUDE_INTENT_JUDGE=1          set inside the judge; gates and the event-log
#                                  hook do nothing there, so no recursion
#   CLAUDE_INTENT_KEEPER=1         set by claude-intent-keeper; it is never gated
#   CLAUDE_INTENT_JUDGE_MODEL      judge model (default below)
#   CLAUDE_INTENT_JUDGE_TIMEOUT    seconds (default 90)
#   CLAUDE_INTENT_JUDGE_CMD        replace the judge command (tests use a stub)
pkgs.writeShellApplication {
  name = "claude-intent-gate";
  runtimeInputs = with pkgs; [
    coreutils
    findutils
    gnugrep
    gnused
    git
    jq
    contextArchive
  ];
  text = ''
    MODE=''${1:-}
    JUDGE_CLAUDE="''${CLAUDE_INTENT_JUDGE_CLAUDE:-${judgeClaude}/bin/claude}"
    JUDGE_MODEL="''${CLAUDE_INTENT_JUDGE_MODEL:-${judgeModel}}"
    JUDGE_TIMEOUT="''${CLAUDE_INTENT_JUDGE_TIMEOUT:-90}"
    VERDICT=""
    REASON=""

    case "$MODE" in
      ask | stop | plan) ;;
      # Exit 1, never 2: for a hook, exit 2 means "block".
      *) printf 'usage: claude-intent-gate {ask|stop|plan} < hook-payload.json\n' >&2; exit 1 ;;
    esac

    PAYLOAD=$(cat 2>/dev/null || true)

    if [ "''${CLAUDE_INTENT_GATES:-1}" = 0 ] || [ "''${CLAUDE_INTENT_JUDGE:-}" = 1 ] || [ "''${CLAUDE_INTENT_KEEPER:-}" = 1 ]; then
      exit 0
    fi
    printf '%s' "$PAYLOAD" | jq -e 'type == "object"' >/dev/null 2>&1 || exit 0

    field() { printf '%s' "$PAYLOAD" | jq -r "$1" 2>/dev/null || true; }

    AGENT_ID=$(field '.agent_id // empty')
    case "$AGENT_ID" in hook-agent-*) exit 0 ;; esac
    CWD=$(field '.cwd // empty')
    if [ -z "$CWD" ] || [ ! -d "$CWD" ]; then CWD=$PWD; fi
    SID=$(field '.session_id // empty')
    TRANSCRIPT=$(field '.transcript_path // empty')
    PMODE=$(field '.permission_mode // empty')
    STATE=$(cd "$CWD" && claude-context-archive dir 2>/dev/null || true)

    log_gate_error() {
      [ -n "$STATE" ] || return 0
      mkdir -p "$STATE" 2>/dev/null || return 0
      jq -cn --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" --arg mode "$MODE" --arg s "$SID" --arg d "$1" \
        '{ ts: $ts, event: "gate-error", mode: $mode, session: $s, detail: $d }' >> "$STATE/events.jsonl" 2>/dev/null || true
    }

    # Any unexpected failure still lets the call through: a hook exiting 2
    # would block, and set -e can exit with whatever status failed.
    # shellcheck disable=SC2329  # invoked by the EXIT trap
    on_exit() {
      local rc=$?
      if [ "$rc" -ne 0 ]; then
        log_gate_error "gate failed (exit $rc)"
        exit 0
      fi
    }
    trap on_exit EXIT

    POLICY=$(cat <<'EOF'
    You are a gate between a coding agent and the user it works for. The user
    would rather agents decide than ask: they review every recorded decision
    afterwards and only want to be interrupted when it matters. The agent may
    decide anything consistent with what the user has said, and should stop and
    ask the user only when:
      1. the choice goes beyond or contradicts what the user said (scope);
      2. it is hard to reverse or reaches outside the repository: deploys,
         deleting or migrating real data, sending anything to anyone, spending
         money, git;
      3. the user's own messages conflict.
    While planning, questions that pin down behavior the user's words do not
    settle are wanted: let those through. Offering optional extra work beyond
    the request ("want me to also ...?") is fine: let it through, since doing it
    unasked would expand scope.
    When you are unsure, ALLOW. Every RETURN must be grounded in the user's words
    below or in the numbered rules above.
    EOF
    )

    ANSWER_FORMAT=$(cat <<'EOF'
    Answer with exactly one first line, ALLOW or RETURN, and nothing else on that
    line. If RETURN, follow it with a short message addressed to the agent: quote
    the user's words that already settle this, or name the rule above that lets
    the agent decide, and say which way the user's words point.
    EOF
    )

    PLAN_TASK=$(cat <<'EOF'
    The agent is about to present the plan below to the user for approval. RETURN
    it if (1) something the user asked for is not addressed, (2) a behavior the
    user's words imply is left undefined (inputs, outputs, errors, edge cases), or
    (3) a behavior has no named test. ALLOW if the plan is complete enough for the
    user to review; missing fine detail is not a gap.
    EOF
    )

    PLAN_ANSWER=$(cat <<'EOF'
    Answer with exactly one first line, ALLOW or RETURN, and nothing else on that
    line. If RETURN, follow it with a short list of the gaps, each saying what is
    missing and, where it comes from the user, quoting the user's words.
    EOF
    )

    user_words() {
      (cd "$CWD" && CLAUDE_CODE_SESSION_ID=$SID claude-context-archive intent 2>/dev/null) | tail -c 30000 || true
    }

    # The agent's last three things said, oldest first.
    recent_context() {
      [ -f "$TRANSCRIPT" ] || return 0
      { tac "$TRANSCRIPT" 2>/dev/null || true; } \
        | jq -rn '[ limit(3; inputs | select(.type == "assistant")
                    | [ .message.content[]? | select(.type == "text") | .text ] | join("\n") | select(length > 0)) ]
                  | reverse | join("\n---\n")' 2>/dev/null \
        | tail -c 6000 || true
    }

    judge_input() { # task item answer-format
      printf "%s\n\n## The user's own messages, oldest first\n%s\n\n## What the agent said most recently\n%s\n\n## %s\n%s\n\n## Your answer\n%s\n" \
        "$POLICY" "$(user_words)" "$(recent_context)" "$1" "$2" "$3"
    }

    run_judge() {
      if [ -n "''${CLAUDE_INTENT_JUDGE_CMD:-}" ]; then
        CLAUDE_INTENT_JUDGE=1 timeout "$JUDGE_TIMEOUT" "$CLAUDE_INTENT_JUDGE_CMD"
      else
        CLAUDE_INTENT_JUDGE=1 timeout "$JUDGE_TIMEOUT" env \
          -u CLAUDE_CODE_SESSION_ID -u CLAUDE_CODE_MESSAGING_SOCKET -u CLAUDE_CODE_MESSAGING_TOKEN \
          -u CLAUDECODE -u CLAUDE_CODE_CHILD_SESSION -u CLAUDE_CODE_ENTRYPOINT \
          "$JUDGE_CLAUDE" -p --model "$JUDGE_MODEL" --tools "" --strict-mcp-config --no-session-persistence --setting-sources user
      fi
    }

    # Sets VERDICT (allow|return) and REASON from the judge's reply; fails on
    # anything that isn't a clear ALLOW, or a RETURN with a reason.
    parse_verdict() {
      local line t first="" rest=""
      while IFS= read -r line || [ -n "$line" ]; do
        if [ -z "$first" ]; then
          t=$(printf '%s' "$line" | tr -d '*`#[:space:]')
          [ -n "$t" ] || continue
          first=$t
          case "$t" in
            ALLOW*) VERDICT="allow"; return 0 ;;
            RETURN*) VERDICT="return"; rest=$(printf '%s' "$line" | sed 's/^[^A-Za-z]*RETURN[-[:space:]:.*]*//') ;;
            *) return 1 ;;
          esac
          continue
        fi
        rest="$rest''${rest:+$'\n'}$line"
      done <<< "$1"
      [ "$VERDICT" = return ] || return 1
      REASON=$(printf '%s\n' "$rest" | sed '/[^[:space:]]/,$!d')
      [ -n "$REASON" ] || return 1
    }

    judge() { # task item answer-format; returns 1 to fail open
      local out
      VERDICT=""
      REASON=""
      out=$(judge_input "$1" "$2" "$3" 2>/dev/null | run_judge 2>/dev/null) || { log_gate_error "judge failed or timed out"; return 1; }
      parse_verdict "$out" || { log_gate_error "unusable judge reply: $(printf '%s' "$out" | tr -s '[:space:]' ' ' | cut -c1-200)"; return 1; }
    }

    mode_ask() {
      local item task next
      item=$(field '[ .tool_input.questions[]?
                      | "Q: \(.question)"
                        + ([ .options[]? | "\n  - \(.label)" + (if (.description // "") != "" then ": \(.description)" else "" end) ] | join("")) ]
                    | join("\n\n")')
      [ -n "$item" ] || return 0
      task="The agent wants to ask the user the question(s) below (AskUserQuestion)."
      if [ "$PMODE" = plan ]; then
        task="$task The agent is planning: RETURN only a question the user's words above already answer; let behavior questions through."
      fi
      judge "$task" "$item" "$ANSWER_FORMAT" || return 0
      [ "$VERDICT" = return ] || return 0
      if [ "$PMODE" = plan ]; then
        next="Decide it yourself, write the decision into the plan along with the user's words it rests on, and continue."
      else
        next="Decide it yourself, record it with claude-context-archive decide (--basis quoting what the user said, or \"not covered\"), and continue."
      fi
      jq -n --arg r "$REASON" --arg next "$next" '{ hookSpecificOutput: { hookEventName: "PreToolUse", permissionDecision: "deny",
        permissionDecisionReason: ("Not asking the user: " + $r + "\n\n" + $next
          + " If this really falls under the stop-and-ask list, ask again and say which rule.") } }'
    }

    mode_stop() {
      local msg tail_part
      [ "$(field '.stop_hook_active')" = true ] && return 0
      # In plan mode, ending the turn to get the plan approved is the point.
      [ "$PMODE" = plan ] && return 0
      msg=$(field '.last_assistant_message // ""')
      if [ "''${#msg}" -gt 400 ]; then tail_part=''${msg: -400}; else tail_part=$msg; fi
      case "$tail_part" in *'?'*) ;; *) return 0 ;; esac
      judge "The agent ended its turn with the message below, which asks the user something. RETURN if the agent should decide and continue instead of waiting for the user." \
        "$msg" "$ANSWER_FORMAT" || return 0
      [ "$VERDICT" = return ] || return 0
      jq -n --arg r "$REASON" '{ decision: "block",
        reason: ("Do not stop to ask the user: " + $r
          + "\n\nDecide it yourself, record it with claude-context-archive decide, say what you decided, and finish without asking.") }'
    }

    # The plan being presented: the newest plans/*.md the agent wrote with a file
    # tool, else (plans written through Bash leave no such call) the newest
    # plans/*.md in the project touched in the last two hours.
    latest_plan_file() {
      local p="" root
      if [ -f "$TRANSCRIPT" ]; then
        p=$({ tac "$TRANSCRIPT" 2>/dev/null || true; } | jq -rn '
              first(inputs | select(.type == "assistant") | .message.content[]?
                    | select(.type == "tool_use" and (.name == "Write" or .name == "Edit" or .name == "MultiEdit"))
                    | (.input.file_path // empty) | select(test("/plans/[^/]+\\.md$")))' 2>/dev/null || true)
      fi
      if [ -z "$p" ] || [ ! -f "$p" ]; then
        root=$(git -C "$CWD" rev-parse --show-toplevel 2>/dev/null || printf '%s' "$CWD")
        p=$(find "$root/plans" -maxdepth 1 -name '*.md' -type f -mmin -120 -printf '%T@ %p\n' 2>/dev/null \
              | sort -rn | head -n 1 | cut -d' ' -f2- || true)
      fi
      printf '%s' "$p"
    }

    mode_plan() {
      local plan path key count=0 statefile
      plan=$(field '.tool_input.plan // empty')
      path=$(field '.tool_input.planFilePath // .tool_input.plan_file_path // empty')
      if [ -z "$plan" ]; then
        path=$(latest_plan_file)
        if [ -n "$path" ] && [ -f "$path" ]; then plan=$(cat "$path"); fi
      fi
      [ -n "$plan" ] || return 0
      key=''${path:-inline}
      statefile="''${STATE:-''${TMPDIR:-/tmp}}/gates/''${SID:-unknown}.plan-returns"
      if [ -f "$statefile" ]; then count=$(grep -cxF -- "$key" "$statefile" || true); fi
      if [ "$count" -ge 2 ]; then
        jq -n '{ systemMessage: "plan check: this plan was sent back twice already; passing it to you as it is." }'
        return 0
      fi
      judge "$PLAN_TASK" "$plan" "$PLAN_ANSWER" || return 0
      [ "$VERDICT" = return ] || return 0
      if mkdir -p "$(dirname "$statefile")" 2>/dev/null; then printf '%s\n' "$key" >> "$statefile"; fi
      jq -n --arg r "$REASON" '{ hookSpecificOutput: { hookEventName: "PreToolUse", permissionDecision: "deny",
        permissionDecisionReason: ("The plan is not ready for the user yet. Gaps against what the user asked for:\n" + $r
          + "\n\nRevise the plan to close them (where a gap is a behavior question only the user can settle, ask the user), then present it again. If a gap is wrong because the plan already covers it, present the plan again as it is: after two rounds this check stands aside and the user decides.") } }'
    }

    case "$MODE" in
      ask) mode_ask ;;
      stop) mode_stop ;;
      plan) mode_plan ;;
    esac
    exit 0
  '';
}
