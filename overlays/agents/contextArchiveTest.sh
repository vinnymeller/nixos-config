# Behavior tests for claude-context-archive. Builds a fake $CLAUDE_CONFIG_DIR
# (projects/ transcripts, sessions/ registry) and a fake archive the way Claude
# Code 2.1.x lays them out, then checks what each subcommand prints.
set -euo pipefail

T=$(mktemp -d)
export HOME="$T/home" TZ=UTC
export CLAUDE_CONFIG_DIR="$HOME/.claude" CLAUDE_CONTEXT_ARCHIVE_DIR="$T/archive"
mkdir -p "$HOME" "$CLAUDE_CONFIG_DIR/projects" "$CLAUDE_CONFIG_DIR/sessions"

mkdir -p "$T/work/proj/sub" "$T/work/proj-clone-2"
repo=$(cd "$T/work/proj" && pwd -P)
clone=$(cd "$T/work/proj-clone-2" && pwd -P)
git -C "$repo" init -q
git -C "$clone" init -q

slug() { printf '%s' "$1" | sed 's/[^A-Za-z0-9]/-/g'; }
PROJ="$CLAUDE_CONFIG_DIR/projects"
A=aaaaaaaa-1111-4111-8111-111111111111 # this conversation: running, at the repo root
B=bbbbbbbb-2222-4222-8222-222222222222 # running, started in repo/sub
C=cccccccc-3333-4333-8333-333333333333 # running, in a sibling clone: never part of the project
D=dddddddd-4444-4444-8444-444444444444 # finished long ago: live transcript deleted, only archived
adir="$PROJ/$(slug "$repo")"
bdir="$PROJ/$(slug "$repo/sub")"
cdir="$PROJ/$(slug "$clone")"
mkdir -p "$adir" "$bdir/$B/subagents" "$cdir"

# Line numbers matter: `show` and intent refs point at them.
#  1 caveat (meta)   2 /clear   3 HUMAN   4 assistant   5 Edit tool_use   6 ack
#  7 AskUserQuestion answer   8 peer message   9 task notification
# 10 compact boundary   11 compact summary   12 HUMAN + image   13 HUMAN mid-turn (queued)
# 14 HUMAN slash command with args   15 ai-title   16 assistant
cat >"$adir/$A.jsonl" <<EOF
{"type":"user","isMeta":true,"cwd":"$repo","sessionId":"$A","timestamp":"2026-11-01T10:00:00.000Z","message":{"role":"user","content":"<local-command-caveat>CAVEAT-TEXT</local-command-caveat>"}}
{"type":"user","cwd":"$repo","sessionId":"$A","timestamp":"2026-11-01T10:00:01.000Z","message":{"role":"user","content":"<command-name>/clear</command-name>\n<command-message>clear</command-message>\n<command-args></command-args>"}}
{"type":"user","origin":{"kind":"human"},"cwd":"$repo","sessionId":"$A","timestamp":"2026-11-01T10:01:00.000Z","message":{"role":"user","content":"Build the zebra importer; it must never drop rows"}}
{"type":"assistant","cwd":"$repo","sessionId":"$A","timestamp":"2026-11-01T10:02:00.000Z","message":{"role":"assistant","content":[{"type":"text","text":"Planning the zebra importer now."}]}}
{"type":"assistant","cwd":"$repo","sessionId":"$A","timestamp":"2026-11-01T10:03:00.000Z","message":{"role":"assistant","content":[{"type":"tool_use","id":"t0","name":"Edit","input":{"file_path":"x.rs","new_string":"ONLY-IN-A-DIFF"}}]}}
{"type":"user","cwd":"$repo","sessionId":"$A","timestamp":"2026-11-01T10:03:01.000Z","message":{"role":"user","content":[{"type":"tool_result","tool_use_id":"t0","content":"The file x.rs has been updated."}]}}
{"type":"user","cwd":"$repo","sessionId":"$A","timestamp":"2026-11-01T10:04:00.000Z","message":{"role":"user","content":[{"type":"tool_result","tool_use_id":"t1","content":"User has answered your questions."}]},"toolUseResult":{"questions":[{"question":"Which storage?","options":[{"label":"Postgres (Recommended)"},{"label":"sqlite"}]}],"answers":{"Which storage?":"Postgres, never sqlite"}}}
{"type":"user","isMeta":true,"origin":{"kind":"peer","name":"other-session"},"cwd":"$repo","sessionId":"$A","timestamp":"2026-11-01T10:05:00.000Z","message":{"role":"user","content":"Another Claude session sent a message: PEER-ONLY-TEXT"}}
{"type":"user","cwd":"$repo","sessionId":"$A","timestamp":"2026-11-01T10:06:00.000Z","message":{"role":"user","content":"<task-notification>TASK-NOTE-TEXT</task-notification>"}}
{"type":"system","subtype":"compact_boundary","content":"Conversation compacted","cwd":"$repo","sessionId":"$A","timestamp":"2026-11-01T10:07:00.000Z"}
{"type":"user","isCompactSummary":true,"isVisibleInTranscriptOnly":true,"cwd":"$repo","sessionId":"$A","timestamp":"2026-11-01T10:07:01.000Z","message":{"role":"user","content":"SUMMARY-TEXT of the earlier conversation"}}
{"type":"user","origin":{"kind":"human"},"cwd":"$repo","sessionId":"$A","timestamp":"2026-11-01T10:08:00.000Z","message":{"role":"user","content":[{"type":"text","text":"Also handle giraffes"},{"type":"image","source":{"type":"base64","media_type":"image/png","data":"AAAA"}}]}}
{"type":"attachment","cwd":"$repo","sessionId":"$A","timestamp":"2026-11-01T10:09:00.000Z","attachment":{"type":"queued_command","prompt":"mid-turn: call it okapi instead","commandMode":"prompt","origin":{"kind":"human"},"timestamp":"2026-11-01T10:09:00.000Z"}}
{"type":"user","origin":{"kind":"human"},"cwd":"$repo","sessionId":"$A","timestamp":"2026-11-01T10:10:00.000Z","message":{"role":"user","content":"<command-name>/xv:interview</command-name>\n<command-message>interview</command-message>\n<command-args>the walrus feature</command-args>"}}
{"type":"ai-title","aiTitle":"Zebra importer","sessionId":"$A"}
{"type":"assistant","cwd":"$repo","sessionId":"$A","timestamp":"2026-11-01T10:11:00.000Z","message":{"role":"assistant","content":[{"type":"text","text":"Zebra importer done. LAST-SAID-A"}]}}
EOF

cat >"$bdir/$B.jsonl" <<EOF
{"type":"user","origin":{"kind":"human"},"cwd":"$repo/sub","sessionId":"$B","timestamp":"2026-11-01T10:05:30.000Z","message":{"role":"user","content":"From the sub dir: koalas need names"}}
{"type":"assistant","cwd":"$repo/sub","sessionId":"$B","timestamp":"2026-11-01T10:06:30.000Z","message":{"role":"assistant","content":[{"type":"text","text":"Working on koala names. LAST-SAID-B"}]}}
{"type":"agent-name","agentName":"worker-b","sessionId":"$B"}
EOF

# A subagent of B: its prompt comes from B (not the user); line 3 is the user
# stepping into the subagent directly.
cat >"$bdir/$B/subagents/agent-b0000001.jsonl" <<EOF
{"type":"user","isSidechain":true,"cwd":"$repo/sub","sessionId":"$B","timestamp":"2026-11-01T10:07:30.000Z","message":{"role":"user","content":"SUBAGENT-PROMPT: research koala naming"}}
{"type":"assistant","isSidechain":true,"cwd":"$repo/sub","sessionId":"$B","timestamp":"2026-11-01T10:07:40.000Z","message":{"role":"assistant","content":[{"type":"text","text":"SUBAGENT-SAID koala names researched"}]}}
{"type":"user","origin":{"kind":"human"},"isSidechain":true,"cwd":"$repo/sub","sessionId":"$B","timestamp":"2026-11-01T10:12:00.000Z","message":{"role":"user","content":"stepped in: koalas must be grey"}}
EOF
printf '{"agentType":"general-purpose","description":"Koala helper"}\n' >"$bdir/$B/subagents/agent-b0000001.meta.json"

cat >"$cdir/$C.jsonl" <<EOF
{"type":"user","origin":{"kind":"human"},"cwd":"$clone","sessionId":"$C","timestamp":"2026-11-01T10:00:30.000Z","message":{"role":"user","content":"CLONE-SECRET zebra plans"}}
EOF

cd "$repo"
archive=$(claude-context-archive dir)
mkdir -p "$archive"
cat >"$archive/$D.jsonl" <<EOF
{"type":"user","origin":{"kind":"human"},"cwd":"$repo","sessionId":"$D","timestamp":"2026-10-01T09:00:00.000Z","message":{"role":"user","content":"archived zebra memory from October"}}
{"type":"custom-title","customTitle":"october-planning","sessionId":"$D"}
EOF
# A pre-compaction snapshot of A (lines 1-9): its live transcript supersedes it.
head -n 9 "$adir/$A.jsonl" >"$archive/$A.jsonl"

now=$(date +%s)
touch -d "@$now" "$adir/$A.jsonl" "$cdir/$C.jsonl"
touch -d "@$((now - 600))" "$bdir/$B.jsonl"
touch -d "@$((now - 120))" "$bdir/$B/subagents/agent-b0000001.jsonl"
touch -d "@$((now - 30 * 86400))" "$archive/$D.jsonl" "$archive/$A.jsonl"

# Registry. This shell ($$) stands in for every running session's process.
have_proc=""
start=""
if [ -r "/proc/$$/stat" ]; then
  have_proc=1
  start=$(sed 's/^.*) //' "/proc/$$/stat" | awk '{print $20}')
fi
sleep 0 &
dead=$!
wait "$dead"
reg() { # file pid procStart session-id name status cwd
  printf '{"pid":%s,"procStart":"%s","sessionId":"%s","name":"%s","status":"%s","cwd":"%s","kind":"interactive","tmux":"t:%s"}\n' \
    "$2" "$3" "$4" "$5" "$6" "$7" "$5" >"$CLAUDE_CONFIG_DIR/sessions/$1.json"
}
reg 1 "$$" "$start" "$A" lead-a busy "$repo"
reg 2 "$$" "$start" "$B" worker-b idle "$repo/sub"
reg 3 "$$" "$start" "$C" clone-c idle "$clone"
reg 4 "$dead" "" eeeeeeee-5555-4555-8555-555555555555 dead-e idle "$repo"
reg 5 "$$" "1" ffffffff-6666-4666-8666-666666666666 recycled-f idle "$repo"

export CLAUDE_CODE_SESSION_ID=$A

fail() {
  printf 'FAIL: %s\n--- output ---\n%s\n--------------\n' "$1" "$2" >&2
  exit 1
}
expect() { grep -qF -- "$2" <<<"$1" || fail "$3: missing [$2]" "$1"; }
reject() { if grep -qF -- "$2" <<<"$1"; then fail "$3: unexpected [$2]" "$1"; fi; }
before() { # output first second label: first appears on an earlier line than second
  local la lb
  la=$(grep -nF -m1 -- "$2" <<<"$1" | cut -d: -f1)
  lb=$(grep -nF -m1 -- "$3" <<<"$1" | cut -d: -f1)
  if [ -z "$la" ] || [ -z "$lb" ] || [ "$la" -ge "$lb" ]; then fail "$4: [$2] should come before [$3]" "$1"; fi
}
pass() { printf 'ok - %s\n' "$1"; }

# --- search: this conversation's live transcript, no compaction required ---
out=$(CLAUDE_CODE_SESSION_ID=$B claude-context-archive search koala)
expect "$out" "$bdir/$B.jsonl:1: user: From the sub dir: koalas need names" "search reads a never-compacted live transcript"
pass "search reads a never-compacted live transcript"

out=$(claude-context-archive search giraffes)
expect "$out" "$adir/$A.jsonl:12: user: Also handle giraffes" "search covers entries after a compaction"
reject "$out" "$archive/" "search prefers the live transcript over its snapshot"
pass "search covers the full history, live file first"

out=$(claude-context-archive search ONLY-IN-A-DIFF)
expect "$out" "No high-signal matches" "search hides diff-only hits"
expect "$out" "1 lower-signal match" "search counts hidden hits"
out=$(claude-context-archive search --raw ONLY-IN-A-DIFF)
expect "$out" "$adir/$A.jsonl:5:" "search --raw shows diff-only hits"
pass "search signal/noise filtering"

out=$(CLAUDE_CODE_SESSION_ID=$D claude-context-archive search october)
expect "$out" "$archive/$D.jsonl:1: user: archived zebra memory from October" "search falls back to the archive"
pass "search falls back to the archive when the live transcript is gone"

# --- search-project: live + archive-only conversations, subdirs, no siblings ---
out=$(claude-context-archive search-project zebra)
expect "$out" "$adir/$A.jsonl:3: user: Build the zebra importer" "search-project finds live hits"
expect "$out" "$archive/$D.jsonl:1:" "search-project finds archive-only conversations"
reject "$out" "CLONE-SECRET" "search-project never reaches a sibling clone"
reject "$out" "$archive/$A.jsonl" "search-project skips snapshots superseded by a live transcript"
out=$(claude-context-archive search-project koala)
expect "$out" "$bdir/$B.jsonl:1:" "search-project includes sessions started in a subdirectory"
pass "search-project scope"

# --- list ---
out=$(claude-context-archive list)
expect "$out" "aaaaaaaa lead-a - Zebra importer [running]" "list labels running sessions"
expect "$out" "<- this conversation" "list marks this conversation"
expect "$out" "bbbbbbbb worker-b" "list includes subdirectory sessions"
expect "$out" "dddddddd october-planning [archived; live transcript deleted]" "list includes archive-only conversations"
reject "$out" "cccccccc" "list never includes a sibling clone"
before "$out" "aaaaaaaa" "bbbbbbbb" "list is newest first"
before "$out" "bbbbbbbb" "dddddddd" "list is newest first"
pass "list"

# --- show: by path, full id, id prefix, subagent prefix ---
out=$(claude-context-archive show aaaaaaaa 3 0)
expect "$out" "> #3 user: Build the zebra importer" "show resolves an id prefix"
out=$(claude-context-archive show "$adir/$A.jsonl" 3 0)
expect "$out" "> #3 user: Build the zebra importer" "show takes a path"
out=$(claude-context-archive show agent-b0000001 3 0)
expect "$out" "> #3 user: stepped in: koalas must be grey" "show resolves a subagent prefix"
pass "show"

# --- intent ---
out=$(claude-context-archive intent)
expect "$out" "from: lead-a (aaaaaaaa), worker-b (bbbbbbbb)" "intent defaults to running sessions"
expect "$out" "-- 2026-11-01 10:01 | lead-a | show aaaaaaaa 3" "intent labels each message with time, session and a show ref"
for s in "Build the zebra importer; it must never drop rows" "Answered: Which storage?" "-> Postgres, never sqlite" \
  "From the sub dir: koalas need names" "Also handle giraffes" "[image]" "mid-turn: call it okapi instead" \
  "/xv:interview the walrus feature" "worker-b/agent-b0000001" "stepped in: koalas must be grey"; do
  expect "$out" "$s" "intent includes every human input"
done
before "$out" "zebra importer;" "Which storage?" "intent is chronological"
before "$out" "Which storage?" "koalas need names" "intent interleaves sessions by time"
before "$out" "koalas need names" "giraffes" "intent is chronological"
before "$out" "giraffes" "okapi" "intent is chronological"
before "$out" "okapi" "walrus" "intent is chronological"
before "$out" "walrus" "grey" "intent is chronological"
for s in CAVEAT-TEXT /clear PEER-ONLY-TEXT TASK-NOTE-TEXT SUMMARY-TEXT SUBAGENT-PROMPT "Planning the zebra" CLONE-SECRET "archived zebra memory"; do
  reject "$out" "$s" "intent excludes everything the user did not type"
done
pass "intent (default scope)"

out=$(claude-context-archive intent --session worker-b)
expect "$out" "koalas need names" "intent --session by running name"
expect "$out" "koalas must be grey" "intent --session includes that session's subagents"
reject "$out" "zebra importer" "intent --session narrows"
out=$(claude-context-archive intent --session aaaaaaaa)
expect "$out" "zebra importer" "intent --session by id prefix"
reject "$out" "koalas" "intent --session narrows"
pass "intent --session"

out=$(claude-context-archive intent --since 1h)
expect "$out" "zebra importer" "intent --since includes recent conversations"
expect "$out" "koalas need names" "intent --since includes recent conversations"
reject "$out" "archived zebra memory" "intent --since excludes older conversations"
out=$(claude-context-archive intent --since 60d)
expect "$out" "archived zebra memory from October" "intent --since reaches archive-only conversations"
expect "$out" "october-planning" "intent labels archived conversations by their name"
if claude-context-archive intent --since soon >/dev/null 2>&1; then fail "intent --since rejects a malformed duration" ""; fi
pass "intent --since"

# --- peers ---
out=$(claude-context-archive peers)
expect "$out" "lead-a  [busy]  aaaaaaaa  interactive   <- this session" "peers lists this session"
expect "$out" "worker-b  [idle]  bbbbbbbb" "peers lists running subdirectory sessions"
expect "$out" "title: Zebra importer" "peers shows the title"
expect "$out" "last said: Zebra importer done. LAST-SAID-A" "peers shows the latest assistant text"
expect "$out" "agent-b0000001  general-purpose  \"Koala helper\"" "peers lists recently active subagents"
expect "$out" "last said: SUBAGENT-SAID koala names researched" "peers shows what a subagent last said"
reject "$out" "clone-c" "peers never lists a sibling clone"
reject "$out" "dead-e" "peers skips sessions whose process is gone"
if [ -n "$have_proc" ]; then reject "$out" "recycled-f" "peers skips a registry entry whose pid was recycled"; fi
pass "peers"

# --- save (PreCompact hook) still snapshots the transcript ---
printf '{"cwd":"%s","transcript_path":"%s","session_id":"%s"}' "$repo" "$adir/$A.jsonl" "$A" | claude-context-archive save
[ "$(wc -l <"$archive/$A.jsonl")" -eq 16 ] || fail "save refreshes the snapshot" "$(wc -l <"$archive/$A.jsonl")"
pass "save"

# --- decide / flag / review ---------------------------------------------------
export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@example.invalid GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@example.invalid
mkdir -p "$repo/src/auth" "$repo/old"
printf '[package]\nname = "x"\n' >"$repo/Cargo.toml"
printf 'fn sign() {}\n' >"$repo/src/auth/token.rs"
printf 'fn other() {}\n' >"$repo/src/other.rs"
printf 'gone\n' >"$repo/old/gone.txt"
git -C "$repo" add -A
commit_epoch=$((now - 3600))
GIT_AUTHOR_DATE="@$commit_epoch +0000" GIT_COMMITTER_DATE="@$commit_epoch +0000" git -C "$repo" commit -qm init
dec="$archive/decisions.jsonl"
exit_code() { local rc=0; "$@" >/dev/null 2>&1 || rc=$?; printf '%s' "$rc"; }

# A decision recorded before the commit: outside review's default scope.
printf '{"id":"d-old000","ts":"%s","kind":"decision","session":"%s","by":"old","what":"OLD-DECISION before the commit","basis":"x","undo":""}\n' \
  "$(date -u -d "@$((commit_epoch - 600))" +%Y-%m-%dT%H:%M:%SZ)" "$A" >>"$dec"

out=$(claude-context-archive decide "Use UTC for all stored timestamps" --basis "user: store timestamps in UTC" --undo "switch the column back" --by tester)
expect "$out" "recorded d-" "decide prints the new id"
id1=${out#recorded }
jq -e --arg a "$A" '.session == $a and .session_name == "lead-a" and .by == "tester" and .kind == "decision" and .basis == "user: store timestamps in UTC"' \
  <<<"$(tail -n 1 "$dec")" >/dev/null || fail "decide records session, running name, --by and basis" "$(tail -n 1 "$dec")"
out=$(claude-context-archive decide "Cache sessions in memory")
id2=${out#recorded }
[ "$id1" != "$id2" ] || fail "decide ids are unique" "$id1 $id2"
[ "$(exit_code claude-context-archive decide --basis only)" = 2 ] || fail "decide without a decision exits 2" ""
[ "$(exit_code claude-context-archive decide "x" --reverses d-nonexistent)" = 2 ] || fail "decide --reverses an unknown id exits 2" ""
out=$(claude-context-archive decide "Keep sessions in redis instead" --basis "user: sessions must survive restarts" --reverses "$id2" --by reviewer)
id3=${out#recorded }
out=$(claude-context-archive decide "Listen on port 8080")
id4=${out#recorded }
long=$(head -c 5000 /dev/zero | tr '\0' a)
claude-context-archive decide "$long" --basis "$long" --undo "$long" >/dev/null
[ "$(tail -n 1 "$dec" | wc -c)" -lt 4096 ] || fail "decide caps fields so a record stays one short line" "$(tail -n 1 "$dec" | wc -c)"
if [ -n "$(find "$repo" -name decisions.jsonl)" ]; then fail "decisions are stored outside the repo" ""; fi
n=$(wc -l <"$dec")
out=$(claude-context-archive decide --help 2>&1)
expect "$out" "usage: claude-context-archive decide" "decide --help prints usage"
[ "$(exit_code claude-context-archive decide --bogus x)" = 2 ] || fail "decide rejects unknown options" ""
out=$(claude-context-archive flag --help 2>&1)
expect "$out" "usage: claude-context-archive flag" "flag --help prints usage"
[ "$(wc -l <"$dec")" -eq "$n" ] || fail "--help and unknown options record nothing" "$(tail -n 2 "$dec")"
pass "decide"

out=$(cd "$repo/src" && claude-context-archive flag "$repo/src/auth/token.rs:10-20" token signing logic --by tester)
expect "$out" "recorded f-" "flag prints the new id"
jq -e '.kind == "flag" and .path == "src/auth/token.rs:10-20" and .why == "token signing logic"' <<<"$(tail -n 1 "$dec")" >/dev/null \
  || fail "flag stores an absolute path repo-relative and keeps the line range" "$(tail -n 1 "$dec")"
(cd "$repo/src" && claude-context-archive flag other.rs "the core of the design" >/dev/null)
jq -e '.path == "src/other.rs"' <<<"$(tail -n 1 "$dec")" >/dev/null || fail "flag resolves a relative path against the cwd" "$(tail -n 1 "$dec")"
[ "$(exit_code claude-context-archive flag only-a-path)" = 2 ] || fail "flag without a reason exits 2" ""
pass "flag"

# Working-tree changes for review's structural section.
printf '[package]\nname = "x"\n[dependencies]\nserde = "1"\n' >"$repo/Cargo.toml"
mkdir -p "$repo/migrations" "$repo/src/newmod" "$repo/.claude"
printf 'create table t ();\n' >"$repo/migrations/0001.sql"
printf 'fn new() {}\n' >"$repo/src/newmod/a.rs"
rm -f "$repo/old/gone.txt"
printf 'fn sign2() {}\n' >"$repo/src/auth/token.rs"
printf 'fn other2() {}\n' >"$repo/src/other.rs"
printf '# always read these\nsrc/auth/*\n' >"$repo/.claude/review-paths"

before_status=$(git -C "$repo" status --porcelain)
out=$(claude-context-archive review)
[ "$before_status" = "$(git -C "$repo" status --porcelain)" ] || fail "review never changes the repo" ""
expect "$out" "Review of $repo: since commit" "review defaults to the last commit"
reject "$out" "OLD-DECISION" "review's default scope excludes decisions before the commit"
for s in "$id1" "Use UTC for all stored timestamps" "basis: user: store timestamps in UTC" "undo: switch the column back" \
  "$id2" "-> reversed by $id3" "(reverses $id2)" "$id4"; do
  expect "$out" "$s" "review lists decisions with basis, undo and reversals"
done
before "$out" "$id1" "$id4" "review lists decisions in time order"
uncovered=$(printf '%s\n' "$out" | sed -n '/^Made without your input/,/^$/p')
expect "$uncovered" "$id4" "decisions without a basis are called out"
reject "$uncovered" "$id2" "a reversed decision is not called out again"
reject "$uncovered" "$id1" "a decision with a basis is not called out"
for s in "Code flagged for you:" "src/auth/token.rs:10-20" "token signing logic" "src/other.rs" "the core of the design"; do
  expect "$out" "$s" "review lists flagged code"
done
for s in "Structural changes in the working tree (vs HEAD):" "paths you marked for review (.claude/review-paths):" \
  "    src/auth/token.rs ( M)" "dependency manifests:" "    Cargo.toml ( M)" "migrations:" "    migrations/0001.sql (??)" \
  "new files:" "    src/newmod/a.rs" "deleted files:" "    old/gone.txt" "untracked"; do
  expect "$out" "$s" "review shows structural changes"
done
reject "$out" " src/other.rs ( M)" "a change outside review-paths is not marked"
out=$(claude-context-archive review --all)
expect "$out" "OLD-DECISION" "review --all includes everything"
out=$(claude-context-archive review --since 10m)
expect "$out" "the last 10m" "review --since sets the scope"
reject "$out" "OLD-DECISION" "review --since excludes older decisions"
[ "$(exit_code claude-context-archive review --since soon)" = 2 ] || fail "review --since rejects a malformed duration" ""
mkdir -p "$T/work/clean"
clean=$(cd "$T/work/clean" && pwd -P)
git -C "$clean" init -q
printf 'x\n' >"$clean/f"
git -C "$clean" add -A
git -C "$clean" commit -qm init
out=$(cd "$clean" && claude-context-archive review)
[ "$(printf '%s\n' "$out" | wc -l)" -eq 1 ] || fail "review of a clean tree with no decisions prints only the header" "$out"
pass "review"

# --- hook (event log) -----------------------------------------------------------
ev="$archive/events.jsonl"
nev() { if [ -f "$ev" ]; then wc -l <"$ev"; else echo 0; fi; }
hook() { printf '%s' "$1" | claude-context-archive hook; }
payload() { # event-name extra-json-fields
  printf '{"session_id":"%s","transcript_path":"%s","cwd":"%s","permission_mode":"default","hook_event_name":"%s"%s}' \
    "$A" "$adir/$A.jsonl" "$repo" "$1" "${2:-}"
}
n=$(nev)
out=$(hook "$(payload UserPromptSubmit ',"prompt":"please add koalas"')")
[ -z "$out" ] || fail "hook prints nothing" "$out"
[ "$(nev)" -eq $((n + 1)) ] || fail "a typed prompt logs one event" "$(tail -n 2 "$ev")"
jq -e --arg a "$A" '.event == "prompt" and .session == $a and .session_name == "lead-a"' <<<"$(tail -n 1 "$ev")" >/dev/null \
  || fail "prompt event carries the session and its running name" "$(tail -n 1 "$ev")"
n=$(nev)
hook "$(payload UserPromptSubmit ',"prompt":"<task-notification>\n<task-id>x</task-id></task-notification>"')"
hook "$(payload UserPromptSubmit ',"prompt":"<command-name>/clear</command-name>\n<command-args></command-args>"')"
[ "$(nev)" -eq "$n" ] || fail "task notifications and bare slash commands are not prompts" "$(tail -n 2 "$ev")"
hook "$(payload UserPromptSubmit ',"prompt":"<command-name>/xv:interview</command-name>\n<command-args>the walrus feature</command-args>"')"
[ "$(nev)" -eq $((n + 1)) ] || fail "a slash command with arguments is a prompt" ""
said=$(head -c 400 /dev/zero | tr '\0' s)
n=$(nev)
hook "$(payload Stop ",\"stop_hook_active\":false,\"last_assistant_message\":\"$said\"")"
jq -e '.event == "turn-end" and (.said | length) == 300 and (has("agent_type") | not)' <<<"$(tail -n 1 "$ev")" >/dev/null \
  || fail "Stop logs a turn-end with what the agent said, capped" "$(tail -n 1 "$ev")"
hook "$(payload SubagentStop ',"agent_id":"a3aa0f5f8053b3c14","agent_type":"general-purpose","last_assistant_message":"sub done"')"
jq -e '.event == "turn-end" and .agent_type == "general-purpose" and .agent_id == "a3aa0f5f8053b3c14" and .said == "sub done"' <<<"$(tail -n 1 "$ev")" >/dev/null \
  || fail "SubagentStop logs a turn-end naming the subagent" "$(tail -n 1 "$ev")"
[ "$(nev)" -eq $((n + 2)) ] || fail "each stop logs exactly one event" ""
n=$(nev)
hook "$(payload Stop ',"agent_id":"hook-agent-6f3f","last_assistant_message":"x"')"
hook "$(payload SubagentStop ',"agent_id":"abc","agent_type":"xv:intent-keeper","last_assistant_message":"x"')"
printf '%s' "$(payload Stop ',"last_assistant_message":"x"')" | CLAUDE_INTENT_JUDGE=1 claude-context-archive hook
printf '%s' "$(payload Stop ',"last_assistant_message":"x"')" | CLAUDE_INTENT_KEEPER=1 claude-context-archive hook
out=$(printf 'not json at all' | claude-context-archive hook) || fail "hook never fails" ""
[ -z "$out" ] || fail "hook prints nothing on garbage" "$out"
[ "$(nev)" -eq "$n" ] || fail "hook agents, the intent-keeper, judges and garbage log nothing" "$(tail -n 3 "$ev")"
pass "hook"

# --- watch ------------------------------------------------------------------------
wout="$T/watch.out"
printf '{"ts":"2026-11-01T10:00:00Z","event":"prompt","session":"%s","session_name":"BEFORE-WATCH"}\n' "$A" >>"$ev"
(timeout 4 claude-context-archive watch >"$wout" 2>/dev/null || true) &
wpid=$!
sleep 1
hook "$(payload UserPromptSubmit ',"prompt":"one more thing"')"
hook "$(payload Stop ',"last_assistant_message":"done with   koalas"')"
claude-context-archive decide "Watch test decision" --by tester >/dev/null
wait "$wpid"
out=$(cat "$wout")
[ "$(printf '%s\n' "$out" | wc -l)" -eq 3 ] || fail "watch prints one line per new event" "$out"
expect "$out" "prompt lead-a (aaaaaaaa): the user said something" "watch formats prompts"
expect "$out" "turn-end lead-a (aaaaaaaa): done with koalas" "watch formats turn-ends"
expect "$out" "by tester: Watch test decision" "watch formats decisions"
before "$out" "prompt lead-a" "turn-end lead-a" "watch keeps event order"
before "$out" "turn-end lead-a" "Watch test decision" "watch keeps event order"
reject "$out" "BEFORE-WATCH" "watch starts at the end of the log"
pass "watch"

if claude-context-archive bogus >/dev/null 2>&1; then fail "unknown subcommand exits non-zero" ""; fi
pass "usage"
echo "all claude-context-archive tests passed"
