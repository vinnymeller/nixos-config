{ pkgs }:
# Conversation history for Claude Code sessions: search, read and summarize
# this project's transcripts, live or archived.
#
#   claude-context-archive search [--raw] <regex>          (this conversation's full history)
#   claude-context-archive search-project [--raw] <regex>  (every conversation in this project)
#   claude-context-archive intent [--since <N>{m,h,d} | --session <id|name>]
#                                                          (only what the user typed, oldest first)
#   claude-context-archive peers                           (running sessions here + their subagents)
#   claude-context-archive list                            (this project's conversations, newest first)
#   claude-context-archive show <file|session-id> <line> [radius]
#                                                          (entries around a line; default radius 5)
#   claude-context-archive decide <what> [--basis ..] [--undo ..] [--by ..] [--reverses <id> | --confirms <id>]
#                                                          (record a decision for the user to review)
#   claude-context-archive flag <file[:lines]> <why> [--by ..]
#                                                          (mark code the user should read)
#   claude-context-archive review [--since <N>{m,h,d} | --all]
#                                                          (decisions + flags since the last commit, and
#                                                           the working tree's structural changes)
#   claude-context-archive watch [--quiet <s>] [--max <s>] (follow the event log in batches; for Monitor)
#   claude-context-archive hook                            (UserPromptSubmit/Stop/SubagentStop hook: log an event)
#   claude-context-archive save                            (PreCompact hook: stdin = hook JSON)
#   claude-context-archive dir                             (print the archive dir for this project)
#
# Sources. Claude Code appends every session's transcript, live, to
# $CLAUDE_CONFIG_DIR/projects/<cwd-slug>/<session-id>.jsonl (subagents under
# <session-id>/subagents/), and compaction never removes earlier entries, so a
# live transcript holds the full history from the first message. Live
# transcripts are therefore the primary source. The PreCompact hook still
# snapshots each transcript into an archive outside any repo (XDG state dir),
# because Claude Code deletes transcripts after cleanupPeriodDays; a snapshot is
# read only when its conversation's live transcript is gone.
#
# A project is the git root of $PWD. Its live transcripts are in the root's slug
# dir plus the dirs of sessions started in its subdirectories (see live_dirs).
# $CLAUDE_CONFIG_DIR/sessions/<pid>.json is Claude Code's registry of running
# sessions (id, cwd, name, busy/idle); intent and peers read it.
#
# search prints `file:line: role: <match-centered snippet>`; the `file:line:`
# prefix feeds straight into `show`. By default search shows only HIGH-SIGNAL
# hits: entries where the term appears in the human-visible text. Hits where the
# term matched only in hidden JSON -- an Edit's diff, a tool_use's input, a
# "file updated" ack, or metadata -- are counted and summarized in a footer, not
# printed (they are almost always noise and drown out real matches). Pass --raw
# to include every rg hit instead.
#
# intent prints only what the human typed, as Claude Code records it: prompts
# marked origin.kind == "human" (including ones sent mid-turn, which arrive as a
# queued_command attachment), answers to AskUserQuestion, and slash commands
# typed with arguments. Peer messages, task notifications, system reminders,
# compaction summaries and subagent prompts carry no human origin, so they are
# excluded by construction rather than by pattern.
pkgs.writeShellApplication {
  name = "claude-context-archive";
  runtimeInputs = with pkgs; [
    coreutils
    gawk
    gnused
    findutils
    jq
    ripgrep
    git
  ];
  text = ''
    ARCHIVE_ROOT="''${CLAUDE_CONTEXT_ARCHIVE_DIR:-''${XDG_STATE_HOME:-$HOME/.local/state}/claude-code/context-archive}"
    CLAUDE_HOME="''${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
    PROJECTS_ROOT="$CLAUDE_HOME/projects"
    SESSIONS_ROOT="$CLAUDE_HOME/sessions"

    # A jq prelude, shared verbatim by render_hits and cmd_show so their view of a
    # transcript entry can never drift. flat/1 turns ANY message content -- a
    # string, an array of blocks, or a nested tool_result whose own .content is an
    # array of blocks -- into a single flat string. It must be TOTAL: an earlier
    # version did `.text // .content` and fed a bare array into join(" "), which
    # threw ("string and array cannot be added", jq exit 5) on tool_results with
    # array content. Recursing instead of indexing keeps every join arg a string.
    # shellcheck disable=SC2016  # the $-names below are jq variables, not shell
    JQ_FLATTEN='
      def flat($c):
        if $c == null then ""
        elif ($c|type) == "string" then $c
        elif ($c|type) == "array" then ([ $c[] | flat(.) ] | join(" "))
        elif ($c|type) == "object" then
          ( ($c.text // $c.content // $c.summary
             // (if $c.type == "tool_use" then "[tool_use " + ($c.name // "?") + "]"
                 elif $c.type == "tool_result" then "[tool_result]"
                 else "" end)) as $inner
            | if ($inner|type) == "string" then $inner else flat($inner) end )
        else ($c|tostring) end;
    '

    # One transcript entry -> the text a human typed in it, or nothing. See the
    # header for why origin.kind (not a text pattern) decides what counts.
    # shellcheck disable=SC2016  # the $-names below are jq variables, not shell
    JQ_HUMAN='
      def txt($c):
        if ($c|type) == "string" then $c
        elif ($c|type) == "array" then
          [ $c[] | if .type == "text" then .text elif .type == "image" then "[image]" else empty end ] | join("\n")
        else "" end;
      # A slash command is stored as <command-name>/<command-args> markup; keep it
      # only when it carried arguments (`/clear` says nothing about intent).
      def cmd($s):
        (first($s | capture("<command-name>(?<n>[^<]*)</command-name>[\\s\\S]*?<command-args>(?<a>[\\s\\S]*?)</command-args>")) // null) as $m
        | if $m == null then $s
          elif ($m.a | test("\\S")) then "\($m.n) \($m.a)"
          else empty end;
      def human:
        if .type == "user" and (.isMeta | not) and .origin.kind? == "human" then cmd(txt(.message.content))
        elif .type == "attachment" and .attachment.type? == "queued_command" and .attachment.origin.kind? == "human" then cmd(txt(.attachment.prompt))
        elif .type == "user" and (.toolUseResult | type) == "object" and (.toolUseResult.answers | type) == "object" then
          .toolUseResult as $r
          | [ $r.answers | to_entries[]
              | "Answered: \(.key)\n-> \(.value)"
                + (($r.annotations[.key].notes // "") | if test("\\S") then "\n(note: \(.))" else "" end) ]
          | join("\n")
        elif .type == "user" and (.message.content | type) == "string" and (.message.content | startswith("<command-name>")) then cmd(.message.content)
        else empty end;
    '

    # The project a directory belongs to: its git root, or the directory itself.
    project_root() { git -C "$1" rev-parse --show-toplevel 2>/dev/null || printf '%s\n' "$1"; }

    # Map a working directory to a stable, collision-free archive subdir. NOTE:
    # only used to NAME a dir under ARCHIVE_ROOT; the archive itself never lives
    # inside the repo.
    project_dir() {
      local root slug
      root=$(project_root "$1")
      slug=$(printf '%s' "$root" | tr -c 'A-Za-z0-9._-' '_')
      printf '%s/%s' "$ARCHIVE_ROOT" "$slug"
    }

    # The conversation id. CLAUDE_CODE_SESSION_ID is exported into both the hook
    # and tool-call environments, so save and search derive the same filename.
    # arg1 is a fallback (e.g. the payload .session_id) used only if it is unset.
    session_id_from() {
      if [ -n "''${CLAUDE_CODE_SESSION_ID:-}" ]; then
        printf '%s' "$CLAUDE_CODE_SESSION_ID"
      else
        printf '%s' "$1"
      fi
    }

    # Portable mtime in epoch seconds (GNU stat, then BSD stat, then 0).
    file_mtime_epoch() { stat -c %Y "$1" 2>/dev/null || stat -f %m "$1" 2>/dev/null || printf 0; }

    # Portable epoch -> local time string (GNU date, then BSD date, then raw).
    fmt_time() { date -d "@$1" '+%Y-%m-%d %H:%M' 2>/dev/null || date -r "$1" '+%Y-%m-%d %H:%M' 2>/dev/null || printf '%s' "$1"; }

    human_age() {
      local d=$1
      [ "$d" -ge 0 ] || d=0
      if [ "$d" -lt 60 ]; then printf '%ds ago' "$d"
      elif [ "$d" -lt 3600 ]; then printf '%dm ago' "$(( d / 60 ))"
      elif [ "$d" -lt 86400 ]; then printf '%dh ago' "$(( d / 3600 ))"
      else printf '%dd ago' "$(( d / 86400 ))"; fi
    }

    # Claude Code's transcript dir name for a cwd: every non-alphanumeric -> '-'.
    live_slug() { printf '%s' "$1" | sed 's/[^A-Za-z0-9]/-/g'; }

    first_cwd() { jq -rn 'first(inputs | objects | .cwd // empty)' "$1" 2>/dev/null || true; }

    # The live transcript dirs of the project rooted at $1, one per line: the
    # root's own dir, plus the dirs of sessions started in its subdirectories,
    # which share the root's slug as a prefix. A prefix alone also matches a
    # sibling such as `repo-clone-2`, so each candidate is confirmed by the cwd
    # recorded in one of its transcripts.
    live_dirs() {
      local root=$1 slug d f c
      slug=$(live_slug "$root")
      if [ -d "$PROJECTS_ROOT/$slug" ]; then printf '%s\n' "$PROJECTS_ROOT/$slug"; fi
      for d in "$PROJECTS_ROOT/$slug"-*; do
        [ -d "$d" ] || continue
        f=$(find "$d" -maxdepth 1 -name '*.jsonl' -type f -print -quit 2>/dev/null || true)
        [ -n "$f" ] || continue
        c=$(first_cwd "$f")
        case "$c" in "$root"/*) printf '%s\n' "$d" ;; esac
      done
    }

    # Every top-level conversation of the project rooted at $1, one path per
    # line: live transcripts, then archived snapshots whose live transcript is
    # gone. A live transcript always contains everything its snapshots do, so
    # listing both would only double every hit.
    conversation_files() {
      local root=$1 d f adir seen=" "
      while IFS= read -r d; do
        for f in "$d"/*.jsonl; do
          [ -f "$f" ] || continue
          printf '%s\n' "$f"
          seen="$seen$(basename "$f") "
        done
      done < <(live_dirs "$root")
      adir=$(project_dir "$root")
      for f in "$adir"/*.jsonl; do
        [ -f "$f" ] || continue
        case "$seen" in *" $(basename "$f") "*) ;; *) printf '%s\n' "$f" ;; esac
      done
    }

    # A session reference -- a transcript path, a session id, or the start of one
    # (`aaaaaaaa`, `agent-a68f5fbc`) -- to one transcript path. A live transcript
    # wins over its archived snapshot. Fails if nothing or several things match.
    resolve_transcript() {
      local ref=$1 matches live n
      if [ -f "$ref" ]; then printf '%s\n' "$ref"; return 0; fi
      [ -n "$ref" ] || return 1
      matches=$(find "$PROJECTS_ROOT" "$ARCHIVE_ROOT" -type f -name "$ref*.jsonl" 2>/dev/null || true)
      [ -n "$matches" ] || return 1
      live=$(printf '%s\n' "$matches" | awk -v p="$ARCHIVE_ROOT/" 'index($0, p) != 1')
      if [ -n "$live" ]; then matches=$live; fi
      n=$(printf '%s\n' "$matches" | wc -l)
      if [ "$n" -gt 1 ]; then
        printf 'Ambiguous session reference %s; it matches:\n%s\n' "$ref" "$matches" >&2
        return 1
      fi
      printf '%s\n' "$matches"
    }

    # Running sessions from Claude Code's registry, as TSV:
    #   session-id  name  status  pid  cwd  kind  tmux  procStart
    # An entry counts only while its process is alive and, where /proc exists,
    # is the same process that registered (start time == procStart), so a
    # recycled pid never resurrects a dead session.
    live_sessions() {
      local f line pid start now_start
      for f in "$SESSIONS_ROOT"/*.json; do
        [ -f "$f" ] || continue
        line=$(jq -r '[.sessionId // "", .name // "", .status // "", (.pid // "" | tostring), .cwd // "", .kind // "", .tmux // "", (.procStart // "" | tostring)] | @tsv' "$f" 2>/dev/null) || continue
        pid=$(printf '%s' "$line" | cut -f4)
        start=$(printf '%s' "$line" | cut -f8)
        [ -n "$pid" ] || continue
        kill -0 "$pid" 2>/dev/null || continue
        if [ -n "$start" ] && [ -r "/proc/$pid/stat" ]; then
          # Field 22 of /proc/<pid>/stat; strip "pid (comm) " first, since comm
          # may itself contain spaces.
          now_start=$(sed 's/^.*) //' "/proc/$pid/stat" 2>/dev/null | awk '{print $20}')
          [ "$now_start" = "$start" ] || continue
        fi
        printf '%s\n' "$line"
      done
    }

    # live_sessions, limited to the project rooted at $1.
    project_live_sessions() {
      live_sessions | awk -F'\t' -v r="$1" '$5 == r || index($5, r "/") == 1'
    }

    # "<name>\t<title>" for a transcript: the name a person or agent gave the
    # session, and Claude Code's generated title. Either may be empty.
    transcript_names() {
      { rg --no-filename -e '"type":"(agent-name|custom-title|ai-title)"' -- "$1" 2>/dev/null || true; } \
        | jq -rs '
            (map(select(.type == "agent-name") | .agentName) | last) as $an
            | (map(select(.type == "custom-title") | .customTitle) | last) as $ct
            | (map(select(.type == "ai-title") | .aiTitle) | last) as $at
            | "\($an // $ct // "")\t\($at // "")"' 2>/dev/null \
        || printf '\t\n'
    }

    # The last thing an agent said (its latest assistant text), on one line.
    last_said() {
      { tac "$1" 2>/dev/null || true; } \
        | jq -rn 'first(inputs | select(.type == "assistant") | .message.content[]? | select(.type == "text") | .text) // ""' 2>/dev/null \
        | tr -s '[:space:]' ' ' | cut -c1-240
    }

    # Every hit of rg (`path:line:rawjson`) -> "<flag>\t<path>:<line>: <role>: <snippet>",
    # in ONE jq process (a jq per hit was the bottleneck on large transcripts).
    # The flag is:
    #   S = signal: the pattern is present in the human-visible flattened text
    #       (snippet is centered on it).
    #   N = noise: rg matched the raw JSON line, but the term is not in the
    #       visible text -- it lives in a diff, tool input, ack, or metadata.
    # A pattern jq cannot compile is treated as S (head snippet), so a rare regex
    # dialect mismatch never hides a real hit. Transcript paths never contain
    # ':', so the first two colons always delimit path and line.
    render_hits() {
      # shellcheck disable=SC2016  # the $-names in the jq program are jq variables, not shell
      jq -rR --arg pat "$1" "$JQ_FLATTEN"'
        index(":") as $a | select($a != null)
        | .[0:$a] as $path | .[$a + 1:] as $rest
        | ($rest | index(":")) as $b | select($b != null)
        | $rest[0:$b] as $ln | $rest[$b + 1:] as $json
        | try (
            ($json | try fromjson catch null) as $o
            | ($o.type // $o.message.role // "?") as $role
            | (try (flat($o.message.content // $o.content // $o.text // $o.summary)) catch "") as $txt
            | (($txt // "") | tostring | gsub("\\s+"; " ")) as $t
            # Offset of the match within the VISIBLE text. "ERR" => the regex would
            # not compile (keep as signal, head snippet); null => compiled cleanly
            # but the term is not visible here (noise); a number => real visible hit.
            | (try ([ $t | match($pat; "i") ][0].offset) catch "ERR") as $off
            | (if $off == "ERR" then "S" elif $off == null then "N" else "S" end) as $flag
            | (if ($off | type) != "number" then $t[0:200]
               else $t[ (if ($off - 40) < 0 then 0 else $off - 40 end) : ($off + 160) ] end) as $snip
            | "\($flag)\t\($path):\($ln): \($role): \($snip)"
          ) catch "S\t\($path):\($ln): ?: (entry could not be rendered; use show)"
      ' 2>/dev/null
    }

    do_search() {
      # arg1 = scope label, arg2 = mode ("signal" hides noise hits, "raw" shows
      # every hit), arg3 = pattern, remaining args = transcript files.
      local label=$1 mode=$2 pat=$3 out body hidden
      shift 3
      out=$(rg -i -H -n --no-heading --no-ignore --sort path -e "$pat" -- "$@" 2>/dev/null | render_hits "$pat") || true
      if [ -z "$out" ]; then
        printf 'No matches for %s in %s.\n' "$pat" "$label"
        return 0
      fi
      if [ "$mode" = raw ]; then
        printf '%s\n' "$out" | cut -f2-
        return 0
      fi
      body=$(printf '%s\n' "$out" | awk -F'\t' '$1 == "S"' | cut -f2-)
      hidden=$(printf '%s\n' "$out" | awk -F'\t' '$1 == "N" { n++ } END { print n + 0 }')
      # Never a silent cap: if we hid anything, say how much and how to see it.
      if [ -z "$body" ]; then
        printf 'No high-signal matches for %s in %s.\n%d lower-signal match(es) (tool acks, diffs, metadata) hidden; re-run with --raw to include them.\n' "$pat" "$label" "$hidden"
        return 0
      fi
      printf '%s\n' "$body"
      if [ "$hidden" -gt 0 ]; then
        printf '  (+%d lower-signal match(es) hidden: tool acks, diffs, metadata; --raw to include)\n' "$hidden"
      fi
    }

    cmd_save() {
      local payload cwd tpath psid sid dir
      payload=$(cat)
      cwd=$(printf '%s' "$payload" | jq -r '.cwd // empty' 2>/dev/null || true)
      tpath=$(printf '%s' "$payload" | jq -r '.transcript_path // empty' 2>/dev/null || true)
      psid=$(printf '%s' "$payload" | jq -r '.session_id // empty' 2>/dev/null || true)
      [ -n "$cwd" ] || cwd=$PWD
      [ -n "$tpath" ] && [ -f "$tpath" ] || exit 0
      sid=$(session_id_from "$psid")
      [ -n "$sid" ] || sid=session
      dir=$(project_dir "$cwd")
      mkdir -p "$dir" 2>/dev/null || exit 0
      # One file per conversation, refreshed on each compaction. The transcript
      # log is cumulative (append-only), so the latest snapshot is the fullest.
      cp -f "$tpath" "$dir/$sid.jsonl" 2>/dev/null || exit 0
      exit 0
    }

    cmd_dir() { project_dir "''${1:-$PWD}"; }

    cmd_list() {
      local root sid now files live epoch f base names name title rname state mark
      root=$(project_root "$PWD")
      sid=$(session_id_from "")
      now=$(date +%s)
      files=$(conversation_files "$root")
      if [ -z "$files" ]; then
        printf 'No conversations found for this project (%s).\n' "$root"
        return 0
      fi
      live=$(project_live_sessions "$root" | cut -f1,2)
      printf 'Conversations in this project, newest first (%s):\n' "$root"
      while IFS= read -r f; do
        printf '%s\t%s\n' "$(file_mtime_epoch "$f")" "$f"
      done <<< "$files" | sort -rn | while IFS=$'\t' read -r epoch f; do
        base=$(basename "$f" .jsonl)
        names=$(transcript_names "$f")
        name=''${names%%$'\t'*}
        title=''${names#*$'\t'}
        rname=$(printf '%s\n' "$live" | awk -F'\t' -v s="$base" '$1 == s { print $2 }')
        state=""
        if [ -n "$rname" ]; then name=$rname; state=" [running]"; fi
        case "$f" in "$ARCHIVE_ROOT"/*) state=" [archived; live transcript deleted]" ;; esac
        mark=""
        if [ "$base" = "$sid" ]; then mark="   <- this conversation"; fi
        printf '  %-8s (%s)  %s%s%s%s  %s%s\n' \
          "$(human_age "$(( now - epoch ))")" "$(fmt_time "$epoch")" "''${base:0:8}" \
          "''${name:+ $name}" "''${title:+ - $title}" "$state" "$f" "$mark"
      done
    }

    cmd_search_conversation() {
      local sid file mode=signal
      if [ "''${1:-}" = "--raw" ]; then mode=raw; shift; fi
      [ "$#" -ge 1 ] || { printf 'usage: claude-context-archive search [--raw] <regex>\n' >&2; return 2; }
      sid=$(session_id_from "")
      if [ -z "$sid" ]; then
        printf 'The current conversation id is unavailable; searching the whole project instead.\n' >&2
        if [ "$mode" = raw ]; then cmd_search_project --raw "$@"; else cmd_search_project "$@"; fi
        return
      fi
      file=$(resolve_transcript "$sid" 2>/dev/null) || file=""
      if [ -z "$file" ]; then
        printf 'No transcript found for this conversation (%s).\nUse search-project to look across all conversations in this project.\n' "$sid"
        return 0
      fi
      do_search "this conversation" "$mode" "$1" "$file"
    }

    cmd_search_project() {
      local root mode=signal
      local -a files=()
      if [ "''${1:-}" = "--raw" ]; then mode=raw; shift; fi
      [ "$#" -ge 1 ] || { printf 'usage: claude-context-archive search-project [--raw] <regex>\n' >&2; return 2; }
      root=$(project_root "$PWD")
      mapfile -t files < <(conversation_files "$root")
      if [ "''${#files[@]}" -eq 0 ]; then
        printf 'No conversations found for this project (%s).\n' "$root"
        return 0
      fi
      do_search "this project" "$mode" "$1" "''${files[@]}"
    }

    cmd_show() {
      local file line radius start end count slice
      file=''${1:-}
      line=''${2:-}
      radius=''${3:-5}
      { [ -n "$file" ] && [ -n "$line" ]; } || { printf 'usage: claude-context-archive show <file|session-id> <line> [radius]\n' >&2; return 2; }
      case "$line" in *[!0-9]*) printf 'line must be a number\n' >&2; return 2 ;; esac
      case "$radius" in *[!0-9]*) radius=5 ;; esac
      file=$(resolve_transcript "$file") || { printf 'No transcript matches %s\n' "$1" >&2; return 2; }
      start=$(( line - radius )); [ "$start" -ge 1 ] || start=1
      end=$(( line + radius ))
      count=$(( end - start + 1 ))
      # Slice the window once. `tail | head` leaves `tail` killed by SIGPIPE when
      # `head` closes early, and under `set -o pipefail` that poisons the whole
      # pipeline's status -- which would spuriously trip the fallback below even
      # when jq rendered fine. So capture into a var (tolerating that status) and
      # feed jq from it; the fallback then only fires on a real jq failure. The
      # 2>/dev/null on tail drops its "Broken pipe" diagnostic (harmless here --
      # the file was already -f checked). `tail | head` (not `head | tail`) stays
      # correct past EOF: it yields lines start..EOF rather than shifting labels.
      slice=$(tail -n +"$start" "$file" 2>/dev/null | head -n "$count") || true
      # shellcheck disable=SC2016  # the $-names in the jq program are jq variables, not shell
      printf '%s\n' "$slice" | jq -rR --argjson start "$start" --argjson focus "$line" "$JQ_FLATTEN"'
        . as $raw
        | (try fromjson catch null) as $o
        | ($start + input_line_number - 1) as $ln
        | (if $ln == $focus then ">" else " " end) as $m
        | ($o.type // $o.message.role // "?") as $role
        | (try (flat($o.message.content // $o.content // $o.text // $o.summary)) catch "") as $txt
        | (($txt // "") | tostring | gsub("\\s+"; " ")) as $t
        | ($o.type // "") as $ty
        | (if ($t|length) > 0 then $t
           elif ($ty == "mode" or $ty == "permission-mode" or $ty == "file-history-snapshot" or $ty == "ai-title" or $ty == "last-prompt" or $ty == "queue-operation" or $ty == "attachment") then ""
           else ($raw | gsub("\\s+"; " ") | .[0:200]) end) as $t2
        | "\($m) #\($ln) \($role): \($t2[0:500])"
      ' 2>/dev/null \
        || printf '%s\n' "$slice" | nl -ba -v "$start" | cut -c1-520
    }

    # One JSON record {ts, label, ref, text} per human input in transcript $1,
    # labeled $2. rg pre-selects the few candidate lines so a 100MB+ transcript
    # costs one fast scan; JQ_HUMAN then decides what really counts.
    human_records() {
      local file=$1 label=$2 ref
      ref=$(basename "$file" .jsonl)
      case "$ref" in agent-*) ref=''${ref:0:14} ;; *) ref=''${ref:0:8} ;; esac
      { rg -n --no-filename -e '"kind":"human"' -e '"answers":\{' -e '<command-args>' -- "$file" 2>/dev/null || true; } \
        | jq -cR --arg label "$label" --arg ref "$ref" "$JQ_HUMAN"'
            index(":") as $a | select($a != null)
            | (.[0:$a] | tonumber) as $ln
            | (.[$a + 1:] | try fromjson catch null) as $o
            | select($o != null)
            | (try ($o | human) catch empty) as $text
            | select($text | test("\\S"))
            | { ts: ($o.timestamp // $o.attachment.timestamp // ""), label: $label, ref: "\($ref) \($ln)", text: $text }
          ' 2>/dev/null || true
    }

    # human_records for a top-level transcript plus any of its subagents the user
    # typed into directly (a subagent's own prompt is not the user's).
    session_human_records() {
      local file=$1 label=$2 sub subdir
      human_records "$file" "$label"
      subdir="$(dirname "$file")/$(basename "$file" .jsonl)/subagents"
      [ -d "$subdir" ] || return 0
      while IFS= read -r sub; do
        [ -n "$sub" ] || continue
        human_records "$sub" "$label/$(basename "$sub" .jsonl | cut -c1-14)"
      done < <(rg -l '"kind":"human"' -g '*.jsonl' -- "$subdir" 2>/dev/null || true)
    }

    cmd_intent() {
      local root sid since="" session="" cutoff now f base names name live label scope listed="" i
      local -a files=() labels=()
      while [ "$#" -gt 0 ]; do
        case "$1" in
          --since | --session)
            [ "$#" -ge 2 ] || { printf 'usage: claude-context-archive intent [--since <N>{m,h,d} | --session <id|name>]\n' >&2; return 2; }
            if [ "$1" = --since ]; then since=$2; else session=$2; fi
            shift 2 ;;
          *) printf 'usage: claude-context-archive intent [--since <N>{m,h,d} | --session <id|name>]\n' >&2; return 2 ;;
        esac
      done
      root=$(project_root "$PWD")
      sid=$(session_id_from "")
      live=$(project_live_sessions "$root" | cut -f1,2)
      if [ -n "$session" ]; then
        # A running session's name, else an id or the start of one.
        base=$(printf '%s\n' "$live" | awk -F'\t' -v n="$session" '$2 == n { print $1; exit }')
        f=$(resolve_transcript "''${base:-$session}") || { printf 'No conversation matches %s.\n' "$session" >&2; return 2; }
        files=("$f")
        scope="session $session"
      elif [ -n "$since" ]; then
        cutoff=$(parse_duration "$since") || {
          printf 'intent: --since takes a whole number with m, h or d (e.g. 90m, 6h, 2d)\n' >&2
          return 2
        }
        now=$(date +%s)
        while IFS= read -r f; do
          [ -n "$f" ] || continue
          if [ "$(( now - $(file_mtime_epoch "$f") ))" -le "$cutoff" ]; then files+=("$f"); fi
        done < <(conversation_files "$root")
        scope="conversations active in the last $since"
      else
        while IFS= read -r base; do
          [ -n "$base" ] || continue
          if f=$(resolve_transcript "$base" 2>/dev/null); then files+=("$f"); fi
        done < <(printf '%s\n%s\n' "$(printf '%s\n' "$live" | cut -f1)" "$sid" | awk 'NF && !seen[$0]++')
        scope="running sessions"
      fi
      if [ "''${#files[@]}" -eq 0 ]; then
        printf 'No conversations in scope (%s) for %s.\nWiden with --since <N>{m,h,d}, or name one with --session <id|name>.\n' "$scope" "$root"
        return 0
      fi
      for f in "''${files[@]}"; do
        base=$(basename "$f" .jsonl)
        name=$(printf '%s\n' "$live" | awk -F'\t' -v s="$base" '$1 == s { print $2 }')
        if [ -z "$name" ]; then names=$(transcript_names "$f"); name=''${names%%$'\t'*}; fi
        label=''${name:-''${base:0:8}}
        labels+=("$label")
        listed="$listed''${listed:+, }$label (''${base:0:8})"
      done
      printf 'Messages typed by the user, oldest first, from: %s\n' "$listed"
      printf 'Scope: %s in %s. Widen with --since <N>{m,h,d}; narrow with --session <id|name>.\n\n' "$scope" "$root"
      for i in "''${!files[@]}"; do
        session_human_records "''${files[$i]}" "''${labels[$i]}"
      done | jq -rs '
        def stamp: . as $s | try (sub("\\.[0-9]+Z$"; "Z") | fromdateiso8601 | strflocaltime("%Y-%m-%d %H:%M")) catch $s;
        if length == 0 then "(no messages from the user in these conversations)" else
          sort_by(.ts)[]
          | (if (.text | length) > 4000
             then .text[0:4000] + "\n... (+\((.text | length) - 4000) more characters; run show for the full message)"
             else .text end) as $t
          | "-- \(.ts | stamp) | \(.label) | show \(.ref)\n" + ($t | split("\n") | map("  " + .) | join("\n")) + "\n"
        end'
    }

    cmd_peers() {
      local root sid now sessions psid name status cwd kind tmux file names title mark subdir sub meta f
      root=$(project_root "$PWD")
      sid=$(session_id_from "")
      now=$(date +%s)
      sessions=$(project_live_sessions "$root")
      if [ -z "$sessions" ]; then
        printf 'No running Claude Code sessions found in %s.\n' "$root"
        return 0
      fi
      printf 'Running sessions in %s (a session name is its SendMessage address; ListAgents gives subagent addresses):\n' "$root"
      while IFS=$'\t' read -r psid name status _ cwd kind tmux _; do
        file=$(resolve_transcript "$psid" 2>/dev/null) || file=""
        title=""
        if [ -n "$file" ]; then names=$(transcript_names "$file"); title=''${names#*$'\t'}; fi
        mark=""
        if [ "$psid" = "$sid" ]; then mark="   <- this session"; fi
        printf '\n%s  [%s]  %s  %s%s\n' "''${name:-?}" "''${status:-?}" "''${psid:0:8}" "$kind" "$mark"
        if [ -n "$title" ]; then printf '  title: %s\n' "$title"; fi
        printf '  cwd: %s%s\n' "$cwd" "''${tmux:+   tmux: $tmux}"
        if [ -z "$file" ]; then printf '  (no transcript found)\n'; continue; fi
        printf '  last active: %s   transcript: %s\n' "$(human_age "$(( now - $(file_mtime_epoch "$file") ))")" "$file"
        printf '  last said: %s\n' "$(last_said "$file" || true)"
        subdir="$(dirname "$file")/$psid/subagents"
        [ -d "$subdir" ] || continue
        sub=$(find "$subdir" -maxdepth 1 -name 'agent-*.jsonl' -type f -mmin -60 2>/dev/null || true)
        [ -n "$sub" ] || continue
        printf '  subagents active in the last hour:\n'
        while IFS= read -r f; do
          printf '%s\t%s\n' "$(file_mtime_epoch "$f")" "$f"
        done <<< "$sub" | sort -rn | while IFS=$'\t' read -r _ f; do
          meta=$(jq -r '"\(.agentType // "?")  \"\(.description // "")\""' "''${f%.jsonl}.meta.json" 2>/dev/null || printf '?')
          printf '    %s  %s  %s\n      last said: %s\n' \
            "$(basename "$f" .jsonl | cut -c1-14)" "$meta" \
            "$(human_age "$(( now - $(file_mtime_epoch "$f") ))")" "$(last_said "$f" || true)"
        done
      done <<< "$sessions"
    }

    # ---- decisions, flags, review, and the event log -------------------------
    #
    # Per-project state lives next to the archive (outside any repo):
    #   decisions.jsonl  decision and flag records (decide, flag; read by review)
    #   events.jsonl     one line per event, for watch: prompt, turn-end (from
    #                    hooks), decision, flag, gate-error
    # Every write is one short line appended with O_APPEND, so concurrent agents
    # never interleave (fields are capped to keep lines small).

    decisions_file() { printf '%s/decisions.jsonl' "$(project_dir "$1")"; }
    events_file() { printf '%s/events.jsonl' "$(project_dir "$1")"; }

    append_line() {
      mkdir -p "$(dirname "$1")" 2>/dev/null || return 0
      printf '%s\n' "$2" >> "$1"
    }

    new_id() { printf '%s-%s' "$1" "$(od -An -N3 -tx1 /dev/urandom | tr -d ' \n')"; }

    now_iso() { date -u '+%Y-%m-%dT%H:%M:%SZ'; }

    # "<N>{m,h,d}" -> seconds; fails on anything else.
    parse_duration() {
      local n unit
      n=''${1%[mhd]}
      unit=''${1#"$n"}
      case "$n" in "" | *[!0-9]*) return 1 ;; esac
      case "$unit" in
        m) printf '%s' "$(( n * 60 ))" ;;
        h) printf '%s' "$(( n * 3600 ))" ;;
        d) printf '%s' "$(( n * 86400 ))" ;;
        *) return 1 ;;
      esac
    }

    # A running session's registry name, or nothing.
    running_name() {
      [ -n "$1" ] || return 0
      live_sessions | awk -F'\t' -v s="$1" '$1 == s { n = $2 } END { print n }'
    }

    usage_decide() {
      printf 'usage: claude-context-archive decide <what you decided> [--basis <the user'"'"'s words it rests on, or "not covered">] [--undo <how to reverse it>] [--by <your name>] [--reverses <id> | --confirms <id>]\n' >&2
    }

    cmd_decide() {
      local what="" basis="" undo="" by="" reverses="" confirms="" ref root file sid id rec
      while [ "$#" -gt 0 ]; do
        case "$1" in
          --basis | --undo | --by | --reverses | --confirms)
            [ "$#" -ge 2 ] || { usage_decide; return 2; }
            case "$1" in
              --basis) basis=$2 ;;
              --undo) undo=$2 ;;
              --by) by=$2 ;;
              --reverses) reverses=$2 ;;
              --confirms) confirms=$2 ;;
            esac
            shift 2 ;;
          -h | --help) usage_decide; return 0 ;;
          --*) printf 'decide: unknown option %s\n' "$1" >&2; usage_decide; return 2 ;;
          *) what="$what''${what:+ }$1"; shift ;;
        esac
      done
      [ -n "$what" ] || { usage_decide; return 2; }
      root=$(project_root "$PWD")
      file=$(decisions_file "$root")
      if [ -n "$reverses" ] && [ -n "$confirms" ]; then
        printf 'decide: a decision either reverses or confirms an earlier one, not both\n' >&2
        return 2
      fi
      ref=''${reverses:-$confirms}
      if [ -n "$ref" ] && ! { [ -f "$file" ] && jq -e --arg id "$ref" 'select(.id == $id)' "$file" >/dev/null 2>&1; }; then
        printf 'decide: no recorded decision has id %s (claude-context-archive review --all lists them)\n' "$ref" >&2
        return 2
      fi
      sid=$(session_id_from "")
      id=$(new_id d)
      rec=$(jq -cn --arg id "$id" --arg ts "$(now_iso)" --arg session "$sid" --arg name "$(running_name "$sid")" \
        --arg by "$by" --arg what "$what" --arg basis "$basis" --arg undo "$undo" --arg rev "$reverses" --arg conf "$confirms" '
          def cap: if length > 1000 then .[0:1000] + "..." else . end;
          { id: $id, ts: $ts, kind: "decision", session: $session, session_name: $name, by: $by,
            what: ($what | cap), basis: ($basis | cap), undo: ($undo | cap) }
          + (if $rev == "" then {} else { reverses: $rev } end)
          + (if $conf == "" then {} else { confirms: $conf } end)')
      append_line "$file" "$rec"
      append_line "$(events_file "$root")" "$(printf '%s' "$rec" | jq -c '{ ts, event: "decision", id, session, session_name, by, what: (.what | .[0:200]) }')"
      printf 'recorded %s\n' "$id"
    }

    cmd_flag() {
      local target="" why="" by="" root path lines rel sid id rec
      while [ "$#" -gt 0 ]; do
        case "$1" in
          --by) [ "$#" -ge 2 ] || { printf 'usage: claude-context-archive flag <file[:lines]> <why the user should read it> [--by <your name>]\n' >&2; return 2; }
            by=$2; shift 2 ;;
          -h | --help) printf 'usage: claude-context-archive flag <file[:lines]> <why the user should read it> [--by <your name>]\n' >&2; return 0 ;;
          --*) printf 'flag: unknown option %s\n' "$1" >&2; return 2 ;;
          *) if [ -z "$target" ]; then target=$1; else why="$why''${why:+ }$1"; fi; shift ;;
        esac
      done
      if [ -z "$target" ] || [ -z "$why" ]; then
        printf 'usage: claude-context-archive flag <file[:lines]> <why the user should read it> [--by <your name>]\n' >&2
        return 2
      fi
      root=$(project_root "$PWD")
      path=''${target%%:*}
      lines=""
      if [ "$path" != "$target" ]; then lines=''${target#*:}; fi
      rel=$(realpath -m --relative-to="$root" -- "$path" 2>/dev/null || printf '%s' "$path")
      sid=$(session_id_from "")
      id=$(new_id f)
      rec=$(jq -cn --arg id "$id" --arg ts "$(now_iso)" --arg session "$sid" --arg name "$(running_name "$sid")" \
        --arg by "$by" --arg path "$rel''${lines:+:$lines}" --arg why "$why" '
          { id: $id, ts: $ts, kind: "flag", session: $session, session_name: $name, by: $by,
            path: $path, why: (if ($why | length) > 1000 then $why[0:1000] + "..." else $why end) }')
      append_line "$(decisions_file "$root")" "$rec"
      append_line "$(events_file "$root")" "$(printf '%s' "$rec" | jq -c '{ ts, event: "flag", id, session, session_name, by, path }')"
      printf 'recorded %s\n' "$id"
    }

    # What changed structurally in the working tree vs HEAD: the parts of a diff
    # a reviewer of architecture wants first. Read-only git (GIT_OPTIONAL_LOCKS=0
    # keeps `git status` from even refreshing the index).
    structural_changes() {
      local root=$1 entry xy p base pat total untracked=0 top
      local -a deps=() migs=() news=() dels=() marked=() patterns=()
      git -C "$root" rev-parse --git-dir >/dev/null 2>&1 || return 0
      if [ -f "$root/.claude/review-paths" ]; then
        while IFS= read -r pat; do
          pat=''${pat%%#*}
          pat=$(printf '%s' "$pat" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')
          if [ -n "$pat" ]; then patterns+=("$pat"); fi
        done < "$root/.claude/review-paths"
      fi
      while IFS= read -r -d $'\0' entry; do
        xy=''${entry:0:2}
        p=''${entry:3}
        case "$xy" in R* | C*) IFS= read -r -d $'\0' _ || true ;; esac
        base=''${p##*/}
        if [ "$xy" = "??" ]; then untracked=$(( untracked + 1 )); fi
        case "$base" in
          Cargo.toml | Cargo.lock | package.json | package-lock.json | pnpm-lock.yaml | yarn.lock | bun.lock | bun.lockb | \
          go.mod | go.sum | pyproject.toml | uv.lock | poetry.lock | requirements*.txt | Gemfile | Gemfile.lock | \
          flake.nix | flake.lock | *.csproj | Package.swift | Package.resolved)
            deps+=("$p ($xy)") ;;
        esac
        case "/$p" in */migration/* | */migrations/*) migs+=("$p ($xy)") ;; esac
        if [ "$xy" = "??" ] || [ "''${xy:0:1}" = A ]; then news+=("$p"); fi
        case "$xy" in *D*) dels+=("$p") ;; esac
        for pat in "''${patterns[@]}"; do
          # shellcheck disable=SC2053  # pat is a glob on purpose
          if [[ $p == $pat ]]; then marked+=("$p ($xy)"); break; fi
        done
      done < <(GIT_OPTIONAL_LOCKS=0 git -C "$root" status --porcelain=v1 -z --untracked-files=all 2>/dev/null || true)
      if [ "''${#deps[@]}" -eq 0 ] && [ "''${#migs[@]}" -eq 0 ] && [ "''${#news[@]}" -eq 0 ] && [ "''${#dels[@]}" -eq 0 ] && [ "''${#marked[@]}" -eq 0 ]; then
        total=$(GIT_OPTIONAL_LOCKS=0 git -C "$root" diff --stat HEAD 2>/dev/null | tail -n 1 | sed 's/^[[:space:]]*//' || true)
        [ -n "$total" ] || return 0
      fi
      printf '\nStructural changes in the working tree (vs HEAD):\n'
      if [ "''${#marked[@]}" -gt 0 ]; then printf '  paths you marked for review (.claude/review-paths):\n'; printf '    %s\n' "''${marked[@]}"; fi
      if [ "''${#deps[@]}" -gt 0 ]; then printf '  dependency manifests:\n'; printf '    %s\n' "''${deps[@]}"; fi
      if [ "''${#migs[@]}" -gt 0 ]; then printf '  migrations:\n'; printf '    %s\n' "''${migs[@]}"; fi
      if [ "''${#news[@]}" -gt 10 ]; then
        printf '  new files (%d), by top-level directory:\n' "''${#news[@]}"
        for p in "''${news[@]}"; do
          top=''${p%%/*}
          if [ "$top" = "$p" ]; then printf '%s\n' "$p"; else printf '%s/\n' "$top"; fi
        done | sort | uniq -c | awk '{ printf "    %s (%d)\n", $2, $1 }'
      elif [ "''${#news[@]}" -gt 0 ]; then
        printf '  new files:\n'; printf '    %s\n' "''${news[@]}"
      fi
      if [ "''${#dels[@]}" -gt 0 ]; then printf '  deleted files:\n'; printf '    %s\n' "''${dels[@]}"; fi
      total=$(GIT_OPTIONAL_LOCKS=0 git -C "$root" diff --stat HEAD 2>/dev/null | tail -n 1 | sed 's/^[[:space:]]*//' || true)
      if [ "$untracked" -gt 0 ]; then total="''${total:+$total; }$untracked untracked"; fi
      printf '  total: %s\n' "''${total:-none}"
    }

    cmd_review() {
      local root since="" all="" file cutoff scope head_ct out
      while [ "$#" -gt 0 ]; do
        case "$1" in
          --since) [ "$#" -ge 2 ] || { printf 'usage: claude-context-archive review [--since <N>{m,h,d} | --all]\n' >&2; return 2; }
            since=$2; shift 2 ;;
          --all) all=1; shift ;;
          -h | --help) printf 'usage: claude-context-archive review [--since <N>{m,h,d} | --all]\n' >&2; return 0 ;;
          *) printf 'usage: claude-context-archive review [--since <N>{m,h,d} | --all]\n' >&2; return 2 ;;
        esac
      done
      root=$(project_root "$PWD")
      file=$(decisions_file "$root")
      if [ -n "$all" ]; then
        cutoff=0
        scope="everything recorded"
      elif [ -n "$since" ]; then
        cutoff=$(parse_duration "$since") || { printf 'review: --since takes a whole number with m, h or d (e.g. 90m, 6h, 2d)\n' >&2; return 2; }
        cutoff=$(( $(date +%s) - cutoff ))
        scope="the last $since"
      else
        head_ct=$(git -C "$root" log -1 --format=%ct 2>/dev/null || true)
        if [ -n "$head_ct" ]; then
          cutoff=$head_ct
          scope="since commit $(git -C "$root" log -1 --format=%h 2>/dev/null) ($(fmt_time "$head_ct"))"
        else
          cutoff=0
          scope="everything recorded (no commits yet)"
        fi
      fi
      printf 'Review of %s: %s\n' "$root" "$scope"
      if [ -s "$file" ]; then
        # shellcheck disable=SC2016  # the $-names in the jq program are jq variables, not shell
        out=$(jq -rs --argjson cutoff "$cutoff" '
          def epoch: (.ts // "" | sub("\\.[0-9]+Z$"; "Z") | try fromdateiso8601 catch 0);
          def stamp: (.ts // "" | sub("\\.[0-9]+Z$"; "Z") | . as $s | try (fromdateiso8601 | strflocaltime("%Y-%m-%d %H:%M")) catch $s);
          def who: ([.by, .session_name] | map(select(. != null and . != "")) | first) // ((.session // "?")[0:8]);
          # No basis, or a basis saying some part is not covered by what the user said.
          def uncovered: ((.basis // "") | test("^\\s*$|not covered"; "i"));
          map(select(type == "object" and epoch >= $cutoff)) | sort_by(.ts) as $recs
          | ($recs | map(select(.kind == "decision"))) as $ds
          | ($recs | map(select(.kind == "flag"))) as $fs
          | (reduce ($ds[] | select(.reverses)) as $d ({}; .[$d.reverses] = $d.id)) as $revby
          | (reduce ($ds[] | select(.confirms)) as $d ({}; .[$d.confirms] += [$d.id])) as $confby
          | (if ($ds | length) > 0 then
               "\nDecisions (\($ds | length)):\n"
               + ([ $ds[]
                    | "  \(.id)  \(stamp)  \(who)"
                      + (if .reverses then "  (reverses \(.reverses))" else "" end)
                      + (if .confirms then "  (confirms \(.confirms))" else "" end)
                      + (if $revby[.id] then "  -> reversed by \($revby[.id])" else "" end)
                      + (if $confby[.id] then "  -> confirmed by \($confby[.id] | join(", "))" else "" end)
                      + "\n    \(.what)"
                      + (if (.basis // "") != "" then "\n    basis: \(.basis)" else "" end)
                      + (if (.undo // "") != "" then "\n    undo: \(.undo)" else "" end) ] | join("\n"))
             else "" end) as $dsec
          | ([ $ds[] | select(uncovered and ($revby[.id] | not)) ]) as $nc
          | (if ($nc | length) > 0 then
               "\n\nMade without your input (basis not covered):\n"
               + ([ $nc[] | "  \(.id)  \(.what | gsub("\\s+"; " ") | .[0:160])"
                            + (if $confby[.id] then "  (confirmed by \($confby[.id] | join(", ")))" else "" end) ] | join("\n"))
             else "" end) as $ncsec
          | (if ($fs | length) > 0 then
               "\n\nCode flagged for you:\n"
               + ([ $fs[] | "  \(.path)  (\(who), \(stamp))\n    \(.why)" ] | join("\n"))
             else "" end) as $fsec
          | $dsec + $ncsec + $fsec' "$file" 2>/dev/null || true)
        if [ -n "$out" ]; then printf '%s\n' "$out"; fi
      fi
      structural_changes "$root"
    }

    # Hook entry point (UserPromptSubmit, Stop, SubagentStop): append one event.
    # Never prints, never fails: a broken log must not disturb the session.
    cmd_hook() {
      local payload cwd root rec sid name
      payload=$(cat 2>/dev/null) || return 0
      if [ "''${CLAUDE_INTENT_JUDGE:-}" = 1 ] || [ "''${CLAUDE_INTENT_KEEPER:-}" = 1 ]; then return 0; fi
      # shellcheck disable=SC2016  # the $-names in the jq program are jq variables, not shell
      rec=$(printf '%s' "$payload" | jq -c --arg ts "$(now_iso)" '
        select(type == "object")
        | (.agent_id // "") as $aid
        | (.agent_type // "") as $at
        | (.last_assistant_message // "" | .[0:300]) as $said
        | if ($aid | startswith("hook-agent-")) or ($at | test("intent-keeper")) then empty
          # Claude Code runs internal helpers (e.g. the next-prompt suggestion) as
          # subagents with no type; real subagents carry one, teammates their name.
          elif .hook_event_name == "SubagentStop" and $at == "" then empty
          elif .hook_event_name == "UserPromptSubmit" then
            (.prompt // "") as $p
            | if ($p | test("^\\s*<(task-notification|cross-session-message|teammate-message|local-command)")) then empty
              elif ($p | test("^\\s*<command-name>"))
                   and (((first($p | capture("<command-args>(?<a>[\\s\\S]*?)</command-args>")) | .a) // "") | test("\\S") | not) then empty
              else { ts: $ts, event: "prompt", session: .session_id } end
          elif .hook_event_name == "Stop" then { ts: $ts, event: "turn-end", session: .session_id, said: $said }
          elif .hook_event_name == "SubagentStop" then
            { ts: $ts, event: "turn-end", session: .session_id, agent_id: $aid, agent_type: $at, said: $said }
          else empty end' 2>/dev/null) || return 0
      [ -n "$rec" ] || return 0
      cwd=$(printf '%s' "$payload" | jq -r '.cwd // empty' 2>/dev/null) || cwd=""
      [ -n "$cwd" ] || cwd=$PWD
      root=$(project_root "$cwd")
      sid=$(printf '%s' "$rec" | jq -r '.session // empty' 2>/dev/null) || sid=""
      name=$(running_name "$sid") || name=""
      rec=$(printf '%s' "$rec" | jq -c --arg n "$name" '. + { session_name: $n }' 2>/dev/null) || return 0
      append_line "$(events_file "$root")" "$rec" || return 0
    }

    # Follow the event log for the Monitor tool, in batches: events are held
    # until --quiet seconds pass with no new one (default 60) or --max seconds
    # after the first held one (default 300), then printed together, so a
    # burst of activity wakes the reader once (Monitor turns lines printed
    # together into one notification). The user's own messages never start a
    # batch; they are only counted in the next one. --quiet 0 prints at once.
    cmd_watch() {
      local file quiet=60 max=300 line rc kind text first=0 prompts=0
      local -a held=()
      while [ "$#" -gt 0 ]; do
        case "$1" in
          --quiet | --max)
            if [ "$#" -lt 2 ] || [[ ! $2 =~ ^[0-9]+$ ]]; then
              printf 'usage: claude-context-archive watch [--quiet <seconds>] [--max <seconds>]\n' >&2
              return 2
            fi
            if [ "$1" = --quiet ]; then quiet=$2; else max=$2; fi
            shift 2 ;;
          *) printf 'usage: claude-context-archive watch [--quiet <seconds>] [--max <seconds>]\n' >&2; return 2 ;;
        esac
      done
      file=$(events_file "$(project_root "$PWD")")
      mkdir -p "$(dirname "$file")"
      touch "$file"
      while true; do
        rc=0
        if [ "$quiet" -gt 0 ]; then IFS= read -r -t "$quiet" line || rc=$?; else IFS= read -r line || rc=$?; fi
        if [ "$rc" -eq 0 ]; then
          kind=''${line%%$'\t'*}
          text=''${line#*$'\t'}
          if [ "$kind" = P ]; then
            prompts=$(( prompts + 1 ))
          else
            held+=("$text")
            if [ "$first" -eq 0 ]; then first=$(date +%s); fi
          fi
        elif [ "$rc" -le 128 ]; then
          break # the log follower is gone
        fi
        # rc > 128: --quiet seconds passed with nothing new.
        if [ "''${#held[@]}" -gt 0 ] && { [ "$rc" -gt 128 ] || [ "$quiet" -eq 0 ] || [ $(( $(date +%s) - first )) -ge "$max" ]; }; then
          printf '%s\n' "''${held[@]}"
          if [ "$prompts" -gt 0 ]; then
            printf '  (the user also sent %d message(s) meanwhile: claude-context-archive intent)\n' "$prompts"
          fi
          held=()
          prompts=0
          first=0
        fi
      done < <(
        # --pid: tail exits once this script is gone (e.g. killed by Monitor or
        # timeout), so no orphaned tail outlives the watch.
        # shellcheck disable=SC2016  # the $-names in the jq program are jq variables, not shell
        tail -n 0 -F --pid=$$ "$file" 2>/dev/null | jq --unbuffered -rR '
          (try fromjson catch null) | select(type == "object")
          | (.ts // "" | sub("\\.[0-9]+Z$"; "Z") | try (fromdateiso8601 | strflocaltime("%H:%M")) catch "--:--") as $t
          | ((.session // "")[0:8]) as $s
          | (if (.session_name // "") != "" then "\(.session_name) (\($s))" else $s end) as $who
          | (if (.by // "") != "" then .by else $who end) as $by
          | if .event == "prompt" then "P\t\($t) prompt \($who)"
            elif .event == "turn-end" then
              "E\t\($t) turn-end \($who)"
              + (if (.agent_type // "") != "" then " / \(.agent_type) \((.agent_id // "")[0:8])" else "" end)
              + ": \(.said // "" | gsub("\\s+"; " ") | .[0:200])"
            elif .event == "decision" then "E\t\($t) decision \(.id) by \($by): \(.what // "" | gsub("\\s+"; " ") | .[0:200])"
            elif .event == "flag" then "E\t\($t) flag \(.id) by \($by): \(.path)"
            elif .event == "gate-error" then "E\t\($t) gate-error \(.mode // "?") \($who): \(.detail // "" | .[0:200])"
            else "E\t\($t) \(.event // "?") \($who)" end'
      )
    }

    case "''${1:-}" in
      save) shift; cmd_save "$@" ;;
      dir) shift; cmd_dir "$@" ;;
      list) shift; cmd_list "$@" ;;
      show) shift; cmd_show "$@" ;;
      intent) shift; cmd_intent "$@" ;;
      peers) shift; cmd_peers "$@" ;;
      decide) shift; cmd_decide "$@" ;;
      flag) shift; cmd_flag "$@" ;;
      review) shift; cmd_review "$@" ;;
      watch) shift; cmd_watch "$@" ;;
      hook) shift; cmd_hook "$@" || true; exit 0 ;;
      search | search-conversation) shift; cmd_search_conversation "$@" ;;
      search-project | search-all) shift; cmd_search_project "$@" ;;
      *) printf 'usage: claude-context-archive {search [--raw] <regex> | search-project [--raw] <regex> | intent [--since <N>{m,h,d} | --session <id|name>] | peers | list | show <file|session-id> <line> [radius] | decide <what> [--basis ..] [--undo ..] [--by ..] [--reverses <id> | --confirms <id>] | flag <file[:lines]> <why> [--by ..] | review [--since <N>{m,h,d} | --all] | watch [--quiet <s>] [--max <s>] | hook | dir | save}\n' >&2; exit 2 ;;
    esac
  '';
}
