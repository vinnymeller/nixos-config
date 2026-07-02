{ pkgs }:
# Full-context archive for Claude Code sessions.
#
#   claude-context-archive save                          (PreCompact hook: stdin = hook JSON)
#   claude-context-archive search [--raw] <regex>        (this conversation's history)
#   claude-context-archive search-project [--raw] <regex>  (all conversations in this project)
#   claude-context-archive list                          (archived conversations, newest first, with timestamps)
#   claude-context-archive show <file> <line> [radius]   (read entries around a hit; default radius 5)
#   claude-context-archive dir                           (print the archive dir for this project)
#
# The PreCompact hook snapshots the transcript BEFORE each (auto or manual)
# compaction, so the agent can grep back for detail that has fallen out of its
# live context. Archives live outside any repo (default: XDG state dir) so full
# transcripts are never accidentally committed.
#
# Files are named by CLAUDE_CODE_SESSION_ID (the conversation id, exported into
# both the hook env and tool-call env) so `save` and `search` agree on the name.
# search prints `file:line: role: <match-centered snippet>`; the `file:line:`
# prefix feeds straight into `show` for the surrounding entries.
#
# By default search shows only HIGH-SIGNAL hits: entries where the term appears
# in the human-visible text. Hits where the term matched only in hidden JSON --
# an Edit's diff, a tool_use's input, a "file updated" ack, or metadata -- are
# counted and summarized in a footer, not printed (they are almost always noise
# and drown out real matches). Pass --raw to include every rg hit instead.
pkgs.writeShellApplication {
  name = "claude-context-archive";
  runtimeInputs = with pkgs; [
    coreutils
    jq
    ripgrep
    git
  ];
  text = ''
    ARCHIVE_ROOT="''${CLAUDE_CONTEXT_ARCHIVE_DIR:-''${XDG_STATE_HOME:-$HOME/.local/state}/claude-code/context-archive}"

    # A jq prelude, shared verbatim by render_hit and cmd_show so their view of a
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

    # Map a working directory to a stable, collision-free archive subdir. Uses
    # the git repo root when available, so any subdir of a project maps to the
    # same archive. NOTE: only used to NAME a dir under ARCHIVE_ROOT; the archive
    # itself never lives inside the repo.
    project_dir() {
      local base=$1 root slug
      root=$(git -C "$base" rev-parse --show-toplevel 2>/dev/null || true)
      [ -n "$root" ] || root=$base
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

    # Flatten one raw JSONL entry (stdin) to a compact "role: text" gist for
    # search previews, centered on the match. Deliberately separate from
    # cmd_show's renderer -- that one also numbers and marks lines; this only
    # needs a one-line gist -- but both share the same content-flattening shape.
    # arg1 = the search pattern.
    #
    # Emits ONE line: "<flag>\t<role>: <snippet>" where flag is:
    #   S = signal: the pattern is present in the human-visible flattened text
    #       (snippet is centered on it).
    #   N = noise: rg matched the raw JSON line, but the term is not in the
    #       visible text -- it lives in a diff, tool input, ack, or metadata.
    # A pattern jq cannot compile is treated as S (head snippet), so a rare regex
    # dialect mismatch never hides a real hit. do_search reads the flag to decide.
    render_hit() {
      # shellcheck disable=SC2016  # the $-names in the jq program are jq variables, not shell
      jq -rR --arg pat "$1" "$JQ_FLATTEN"'
        (try fromjson catch null) as $o
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
        | "\($flag)\t\($role): \($snip)"
      ' 2>/dev/null
    }

    do_search() {
      # arg1 = file or dir to search, arg2 = pattern, arg3 = scope label,
      # arg4 = mode ("signal" hides noise hits [default], "raw" shows every hit).
      # -H -n --no-heading => rg emits `path:line:rawjson` per hit. We keep the
      # `path:line:` prefix (so a hit still feeds `show`) but swap the raw JSON
      # for a rendered "role: text" gist so hits can be triaged inline. Paths in
      # the archive never contain ':', so splitting on the first two is safe.
      local mode=''${4:-signal}
      local matches hit path rest lno json rendered flag gist shown=0 hidden=0
      matches=$(rg -i -H -n --no-heading --no-ignore -e "$2" "$1" 2>/dev/null) || true
      if [ -z "$matches" ]; then
        printf 'No matches for %s in %s.\n' "$2" "$3"
        return 0
      fi
      while IFS= read -r hit; do
        path=''${hit%%:*}
        rest=''${hit#*:}
        lno=''${rest%%:*}
        json=''${rest#*:}
        rendered=$(printf '%s' "$json" | render_hit "$2") || true
        flag=''${rendered%%$'\t'*}
        gist=''${rendered#*$'\t'}
        if [ "$mode" = raw ] || [ "$flag" = S ]; then
          printf '%s:%s: %s\n' "$path" "$lno" "$gist"
          shown=$(( shown + 1 ))
        else
          hidden=$(( hidden + 1 ))
        fi
      done <<< "$matches"
      # Never a silent cap: if we hid anything, say how much and how to see it.
      if [ "$shown" -eq 0 ] && [ "$hidden" -gt 0 ]; then
        printf 'No high-signal matches for %s in %s.\n%d lower-signal match(es) (tool acks, diffs, metadata) hidden; re-run with --raw to include them.\n' "$2" "$3" "$hidden"
      elif [ "$mode" != raw ] && [ "$hidden" -gt 0 ]; then
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
      local dir sid now
      dir=$(project_dir "$PWD")
      sid=$(session_id_from "")
      if [ ! -d "$dir" ]; then
        printf 'No context archive yet for this project.\n(expected under: %s)\n' "$dir"
        return 0
      fi
      now=$(date +%s)
      printf 'Archived conversations for this project (newest first):\n  %s\n' "$dir"
      find "$dir" -maxdepth 1 -name '*.jsonl' -type f -print 2>/dev/null | while IFS= read -r f; do
        printf '%s\t%s\n' "$(file_mtime_epoch "$f")" "$f"
      done | sort -rn | while IFS=$'\t' read -r epoch f; do
        mark=""
        case "$f" in *"/$sid.jsonl") mark="   <- this conversation" ;; esac
        printf '  %-8s (%s)  %s%s\n' "$(human_age "$(( now - epoch ))")" "$(fmt_time "$epoch")" "$f" "$mark"
      done
    }

    cmd_search_conversation() {
      local dir sid file mode=signal
      if [ "''${1:-}" = "--raw" ]; then mode=raw; shift; fi
      [ "$#" -ge 1 ] || { printf 'usage: claude-context-archive search [--raw] <regex>\n' >&2; return 2; }
      dir=$(project_dir "$PWD")
      sid=$(session_id_from "")
      if [ -z "$sid" ]; then
        printf 'The current conversation id is unavailable; searching the whole project instead.\n' >&2
        if [ "$mode" = raw ]; then cmd_search_project --raw "$@"; else cmd_search_project "$@"; fi
        return
      fi
      file="$dir/$sid.jsonl"
      if [ ! -f "$file" ]; then
        printf 'Nothing archived for this conversation yet (nothing has compacted).\nUse search-project to look across all conversations, or the list command to see recent archives.\n'
        return 0
      fi
      do_search "$file" "$1" "this conversation" "$mode"
    }

    cmd_search_project() {
      local dir mode=signal
      if [ "''${1:-}" = "--raw" ]; then mode=raw; shift; fi
      [ "$#" -ge 1 ] || { printf 'usage: claude-context-archive search-project [--raw] <regex>\n' >&2; return 2; }
      dir=$(project_dir "$PWD")
      if [ ! -d "$dir" ]; then
        printf 'No context archive yet for this project (%s).\n' "$dir"
        return 0
      fi
      do_search "$dir" "$1" "this project archive" "$mode"
    }

    cmd_show() {
      local file line radius alt start end count slice
      file=''${1:-}
      line=''${2:-}
      radius=''${3:-5}
      { [ -n "$file" ] && [ -n "$line" ]; } || { printf 'usage: claude-context-archive show <file> <line> [radius]\n' >&2; return 2; }
      case "$line" in *[!0-9]*) printf 'line must be a number\n' >&2; return 2 ;; esac
      case "$radius" in *[!0-9]*) radius=5 ;; esac
      # Accept a bare session id as well as a path.
      if [ ! -f "$file" ]; then
        alt="$(project_dir "$PWD")/$file.jsonl"
        [ -f "$alt" ] && file="$alt"
      fi
      [ -f "$file" ] || { printf 'No such archive file: %s\n' "$file" >&2; return 2; }
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

    case "''${1:-}" in
      save) shift; cmd_save "$@" ;;
      dir) shift; cmd_dir "$@" ;;
      list) shift; cmd_list "$@" ;;
      show) shift; cmd_show "$@" ;;
      search | search-conversation) shift; cmd_search_conversation "$@" ;;
      search-project | search-all) shift; cmd_search_project "$@" ;;
      *) printf 'usage: claude-context-archive {search [--raw] <regex> | search-project [--raw] <regex> | show <file> <line> [radius] | list | dir | save}\n' >&2; exit 2 ;;
    esac
  '';
}
