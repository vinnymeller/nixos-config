# Behavior tests for claude-intent-gate. The judge is replaced by a stub
# (CLAUDE_INTENT_JUDGE_CMD) that records what it was given and answers as told,
# so everything around the model is tested: when the judge runs, what it sees,
# how its verdict becomes hook output, and that every failure lets work through.
set -euo pipefail

T=$(mktemp -d)
export HOME="$T/home" TZ=UTC
export CLAUDE_CONFIG_DIR="$HOME/.claude" CLAUDE_CONTEXT_ARCHIVE_DIR="$T/archive"
mkdir -p "$HOME" "$CLAUDE_CONFIG_DIR/projects"
mkdir -p "$T/work/proj/plans"
repo=$(cd "$T/work/proj" && pwd -P)
git -C "$repo" init -q

G=99999999-1111-4111-8111-111111111111
slug=$(printf '%s' "$repo" | sed 's/[^A-Za-z0-9]/-/g')
tdir="$CLAUDE_CONFIG_DIR/projects/$slug"
mkdir -p "$tdir"
tr="$tdir/$G.jsonl"
printf 'PLAN-FROM-FILE: buttons are blue\n' >"$repo/plans/p1.md"
cat >"$tr" <<EOF
{"type":"user","origin":{"kind":"human"},"cwd":"$repo","sessionId":"$G","timestamp":"2026-11-01T10:00:00.000Z","message":{"role":"user","content":"Use blue for every button."}}
{"type":"assistant","cwd":"$repo","sessionId":"$G","timestamp":"2026-11-01T10:01:00.000Z","message":{"role":"assistant","content":[{"type":"text","text":"AGENT-RECENT: adding the settings button now."}]}}
{"type":"assistant","cwd":"$repo","sessionId":"$G","timestamp":"2026-11-01T10:02:00.000Z","message":{"role":"assistant","content":[{"type":"tool_use","id":"w1","name":"Write","input":{"file_path":"$repo/plans/p1.md","content":"PLAN-FROM-FILE"}}]}}
EOF
cd "$repo"
events="$(claude-context-archive dir)/events.jsonl"

stub="$T/stub-judge"
printf '#!%s\n' "$(command -v bash)" >"$stub"
cat >>"$stub" <<'EOF'
cat >"$STUB_DIR/input"
env >"$STUB_DIR/env"
touch "$STUB_DIR/called"
case "${STUB_MODE:-allow}" in
  allow) printf 'ALLOW\n' ;;
  return) printf '**RETURN**\nThe user already said: "Use blue for every button."\n' ;;
  return-inline) printf 'RETURN: the user said blue\n' ;;
  return-empty) printf 'RETURN\n\n' ;;
  garbage) printf 'I think maybe?\n' ;;
  fail) exit 1 ;;
  slow) sleep 5; printf 'ALLOW\n' ;;
esac
EOF
chmod +x "$stub"
export CLAUDE_INTENT_JUDGE_CMD="$stub" CLAUDE_INTENT_JUDGE_TIMEOUT=2

fail() {
  printf 'FAIL: %s\n--- output ---\n%s\n--------------\n' "$1" "$2" >&2
  exit 1
}
expect() { grep -qF -- "$2" <<<"$1" || fail "$3: missing [$2]" "$1"; }
pass() { printf 'ok - %s\n' "$1"; }

# gate MODE STUB_MODE PAYLOAD [env assignments...]: runs the gate with a fresh
# stub dir; sets OUT, RC and SD (the stub dir).
gate() {
  local mode=$1 smode=$2 payload=$3
  shift 3
  SD=$(mktemp -d)
  RC=0
  OUT=$(printf '%s' "$payload" | env STUB_DIR="$SD" STUB_MODE="$smode" "$@" claude-intent-gate "$mode") || RC=$?
}
called() { [ -f "$SD/called" ]; }
nevents() { if [ -f "$events" ]; then wc -l <"$events"; else echo 0; fi; }

ask_payload() { # permission-mode [extra-fields]
  printf '{"session_id":"%s","transcript_path":"%s","cwd":"%s","permission_mode":"%s","hook_event_name":"PreToolUse","tool_name":"AskUserQuestion","tool_input":{"questions":[{"question":"Which color should the settings button be?","header":"Color","options":[{"label":"Red","description":"warm"},{"label":"Blue"}],"multiSelect":false}]},"tool_use_id":"t1"%s}' \
    "$G" "$tr" "$repo" "$1" "${2:-}"
}
stop_payload() { # stop_hook_active last_assistant_message
  jq -cn --arg s "$G" --arg t "$tr" --arg c "$repo" --argjson a "$1" --arg m "$2" \
    '{session_id: $s, transcript_path: $t, cwd: $c, permission_mode: "default", hook_event_name: "Stop", stop_hook_active: $a, last_assistant_message: $m}'
}
plan_payload() { # tool_input-json
  jq -cn --arg s "$G" --arg t "$tr" --arg c "$repo" --argjson i "$1" \
    '{session_id: $s, transcript_path: $t, cwd: $c, permission_mode: "plan", hook_event_name: "PreToolUse", tool_name: "ExitPlanMode", tool_input: $i}'
}

# --- ask ---
gate ask return "$(ask_payload default)"
[ "$RC" -eq 0 ] || fail "ask exits 0" "$RC"
jq -e '.hookSpecificOutput.hookEventName == "PreToolUse" and .hookSpecificOutput.permissionDecision == "deny"' <<<"$OUT" >/dev/null \
  || fail "ask RETURN denies the question" "$OUT"
reason=$(jq -r '.hookSpecificOutput.permissionDecisionReason' <<<"$OUT")
expect "$reason" 'The user already said: "Use blue for every button."' "the deny reason carries the judge's reason"
expect "$reason" "claude-context-archive decide" "the deny reason tells the agent to record the decision"
input=$(cat "$SD/input")
for s in "Q: Which color should the settings button be?" "  - Red: warm" "  - Blue" "Use blue for every button." \
  "AGENT-RECENT: adding the settings button now." "the user's own messages conflict" "ALLOW or RETURN"; do
  expect "$input" "$s" "the judge sees the question, its options, the user's words, the agent's recent words and the policy"
done
grep -qx 'CLAUDE_INTENT_JUDGE=1' "$SD/env" || fail "the judge runs with CLAUDE_INTENT_JUDGE=1" "$(cat "$SD/env")"
gate ask allow "$(ask_payload default)"
{ [ "$RC" -eq 0 ] && [ -z "$OUT" ] && called; } || fail "ask ALLOW lets the question through silently" "$OUT"
gate ask return-inline "$(ask_payload default)"
expect "$(jq -r '.hookSpecificOutput.permissionDecisionReason' <<<"$OUT")" "the user said blue" "a reason on the RETURN line is kept"
gate ask return "$(ask_payload plan)"
expect "$(cat "$SD/input")" "The agent is planning" "in plan mode the judge is told the agent is planning"
reason=$(jq -r '.hookSpecificOutput.permissionDecisionReason' <<<"$OUT")
expect "$reason" "write the decision into the plan" "in plan mode a returned question goes into the plan"
if grep -qF "claude-context-archive decide" <<<"$reason"; then fail "in plan mode the agent is not told to run decide" "$reason"; fi
pass "ask"

# --- fail open ---
for m in fail garbage slow return-empty; do
  n=$(nevents)
  gate ask "$m" "$(ask_payload default)"
  { [ "$RC" -eq 0 ] && [ -z "$OUT" ]; } || fail "judge '$m' fails open" "rc=$RC out=$OUT"
  [ "$(nevents)" -eq $((n + 1)) ] || fail "judge '$m' logs a gate-error event" "$(tail -n 2 "$events" 2>/dev/null)"
  jq -e '.event == "gate-error" and .mode == "ask"' <<<"$(tail -n 1 "$events")" >/dev/null || fail "gate-error event shape" "$(tail -n 1 "$events")"
done
gate ask return 'not json'
{ [ "$RC" -eq 0 ] && [ -z "$OUT" ] && ! called; } || fail "a garbage payload is let through without judging" "$OUT"
RC=0
printf '{}' | claude-intent-gate bogus >/dev/null 2>&1 || RC=$?
[ "$RC" -eq 1 ] || fail "an unknown mode exits 1, never 2 (2 would block)" "$RC"
pass "fail open"

# --- skips ---
gate ask return "$(ask_payload default)" CLAUDE_INTENT_GATES=0
{ [ -z "$OUT" ] && ! called; } || fail "CLAUDE_INTENT_GATES=0 disables the gate" "$OUT"
gate ask return "$(ask_payload default)" CLAUDE_INTENT_JUDGE=1
{ [ -z "$OUT" ] && ! called; } || fail "the gate does nothing inside a judge" "$OUT"
gate ask return "$(ask_payload default)" CLAUDE_INTENT_KEEPER=1
{ [ -z "$OUT" ] && ! called; } || fail "the intent-keeper is never gated" "$OUT"
gate ask return "$(ask_payload default ',"agent_id":"hook-agent-123"')"
{ [ -z "$OUT" ] && ! called; } || fail "hook agents are never gated" "$OUT"
pass "skips"

# --- stop ---
gate stop return "$(stop_payload true 'Should I use approach A or B?')"
{ [ -z "$OUT" ] && ! called; } || fail "stop does nothing once stop_hook_active" "$OUT"
gate stop return "$(stop_payload false 'All done. The tests pass.')"
{ [ -z "$OUT" ] && ! called; } || fail "stop does not judge a message without a question" "$OUT"
early="Is this right? $(head -c 500 /dev/zero | tr '\0' x) All done."
gate stop return "$(stop_payload false "$early")"
{ [ -z "$OUT" ] && ! called; } || fail "stop only looks for a question near the end" "$OUT"
gate stop return "$(jq -c '.permission_mode = "plan"' <<<"$(stop_payload false 'Here is the plan. Approve it?')")"
{ [ -z "$OUT" ] && ! called; } || fail "stop never judges in plan mode (asking for approval is the point)" "$OUT"
gate stop return "$(stop_payload false 'Implemented the cache. Should I use approach A or B?')"
jq -e '.decision == "block" and (.reason | contains("Use blue for every button.")) and (.reason | contains("claude-context-archive decide"))' <<<"$OUT" >/dev/null \
  || fail "stop RETURN blocks with the reason" "$OUT"
expect "$(cat "$SD/input")" "Implemented the cache. Should I use approach A or B?" "the judge sees the final message"
gate stop allow "$(stop_payload false 'Want me to also add X?')"
{ [ -z "$OUT" ] && called; } || fail "stop ALLOW lets the turn end" "$OUT"
pass "stop"

# --- plan ---
gate plan return "$(plan_payload '{"plan":"INLINE-PLAN: add a blue button"}')"
expect "$(cat "$SD/input")" "INLINE-PLAN: add a blue button" "the judge sees tool_input.plan"
jq -e '.hookSpecificOutput.permissionDecision == "deny" and (.hookSpecificOutput.permissionDecisionReason | contains("not ready"))' <<<"$OUT" >/dev/null \
  || fail "plan RETURN sends the plan back" "$OUT"
expect "$(jq -r '.hookSpecificOutput.permissionDecisionReason' <<<"$OUT")" "present the plan again as it is" "a returned plan tells the agent how to disagree"
gate plan allow '{"session_id":"'"$G"'","transcript_path":"'"$tr"'","cwd":"'"$repo"'","hook_event_name":"PreToolUse","tool_name":"ExitPlanMode","tool_input":{}}'
expect "$(cat "$SD/input")" "PLAN-FROM-FILE: buttons are blue" "without tool_input.plan the plan is read from the latest plans/ write"
for i in 1 2; do
  gate plan return "$(plan_payload '{"planFilePath":"/x/plans/capped.md","plan":"CAPPED"}')"
  called || fail "plan returns are judged until the cap ($i)" "$OUT"
done
gate plan return "$(plan_payload '{"planFilePath":"/x/plans/capped.md","plan":"CAPPED"}')"
{ ! called && jq -e '.systemMessage | contains("sent back twice")' <<<"$OUT" >/dev/null; } || fail "a plan sent back twice passes with a note" "$OUT"
gate plan return "$(plan_payload '{"planFilePath":"/x/plans/other.md","plan":"OTHER"}')"
called || fail "the cap is per plan file" "$OUT"
pass "plan"

echo "all claude-intent-gate tests passed"
