#!/usr/bin/env bash

MODEL="@MODEL_PATH@"
GEMINI_KEY_FILE="@GEMINI_KEY_FILE@"
PIDFILE="/tmp/vtt.pid"
AUDIOFILE="/tmp/vtt.wav"
LOGFILE="/tmp/vtt.log"
SCREENSHOTFILE="/tmp/vtt-screenshot.jpg"
CORRECT=false
CONTEXT=false

# Parse arguments
for arg in "$@"; do
	case "$arg" in
	--correct)
		CORRECT=true
		;;
	--context)
		CONTEXT=true
		;;
	esac
done

log() {
	echo "[$(date '+%H:%M:%S.%3N')] $*" >>"$LOGFILE"
}

get_context() {
	local window_json class title context pid

	window_json=$(hyprctl activewindow -j 2>/dev/null) || return
	class=$(echo "$window_json" | jq -r '.class // empty')
	title=$(echo "$window_json" | jq -r '.title // empty')
	pid=$(echo "$window_json" | jq -r '.pid // empty')

	log "get_context: class='${class}' title='${title}' pid='${pid}'"

	context="Active application: ${class}"
	if [ -n "$title" ]; then
		context="${context}\nWindow title: ${title}"
	fi

	# If it's a terminal, try to get tmux context
	local got_tmux=false
	if [[ "$class" =~ ^(kitty|foot|Alacritty|org\.wezfurlong\.wezterm)$ ]] && [ -n "$pid" ]; then
		local tmux_pane
		tmux_pane=$(find_tmux_pane "$pid")
		log "get_context: tmux_pane='${tmux_pane}'"
		if [ -n "$tmux_pane" ]; then
			local pane_content
			pane_content=$(tmux capture-pane -t "$tmux_pane" -p -S -50 2>/dev/null)
			if [ -n "$pane_content" ]; then
				context="${context}\n\nTerminal context (last 50 lines):\n${pane_content}"
				got_tmux=true
			fi
		fi
	fi

	# For non-tmux apps, take a screenshot of the active window
	if [ "$got_tmux" = false ]; then
		rm -f "$SCREENSHOTFILE"
		if hyprshot -m window -m active --raw --silent >"$SCREENSHOTFILE" 2>/dev/null && [ -s "$SCREENSHOTFILE" ]; then
			log "get_context: captured screenshot ($(wc -c <"$SCREENSHOTFILE") bytes)"
		else
			log "get_context: screenshot failed"
			rm -f "$SCREENSHOTFILE"
		fi
	fi

	echo -e "$context"
}

find_tmux_pane() {
	local window_pid="$1"

	# Get tmux clients mapped to their active pane
	local tmux_clients
	tmux_clients=$(tmux list-clients -F '#{client_pid} #{pane_id}' 2>/dev/null) || return

	# Walk descendant tree to find a tmux client process
	local queue="$window_pid"
	while [ -n "$queue" ]; do
		local next_queue=""
		for pid in $queue; do
			# Check if this PID is a tmux client
			local match
			match=$(echo "$tmux_clients" | awk -v pid="$pid" '$1 == pid { print $2 }')
			if [ -n "$match" ]; then
				echo "$match"
				return
			fi
			local children
			children=$(pgrep -P "$pid" 2>/dev/null) || true
			if [ -n "$children" ]; then
				next_queue="${next_queue} ${children}"
			fi
		done
		queue="$next_queue"
	done
}

gemini_correct() {
	local raw_text="$1"
	local context="$2"

	local gemini_key
	gemini_key=$(cat "$GEMINI_KEY_FILE" 2>/dev/null) || {
		log "gemini_correct: failed to read API key"
		echo "$raw_text"
		return
	}

	local system_instruction
	system_instruction="You are a voice-to-text assistant. You receive raw speech-to-text output and process it. There are two modes:

1. If the user is making an explicit request to *you*(e.g. 'Gemini, write me a thank you note', 'Assistant, summarize this', 'Gemini, translate to French'), fulfill that request. Output ONLY the result, nothing else.

2. Otherwise, clean up the transcription:
- Fix grammar, punctuation, and capitalization
- Fix misheard words, especially technical/domain terms
- Preserve the user's intended meaning and tone
- Output ONLY the cleaned up text, nothing else"

	if [ -n "$context" ]; then
		system_instruction="${system_instruction}

Context about what the user is doing:
${context}

Use this context to better understand domain-specific terms and what the user likely meant."
	fi

	# Build content parts: text + optional screenshot
	local parts_json
	parts_json=$(jq -n --arg text "$raw_text" '[{ text: $text }]')

	if [ -s "$SCREENSHOTFILE" ]; then
		local img_b64
		img_b64=$(base64 -w 0 "$SCREENSHOTFILE")
		parts_json=$(echo "$parts_json" | jq --arg img "$img_b64" \
			'. + [{ inlineData: { mimeType: "image/jpeg", data: $img } }]')
		log "gemini_correct: including screenshot in request"
		rm -f "$SCREENSHOTFILE"
	fi

	local payload
	payload=$(jq -n \
		--arg system "$system_instruction" \
		--argjson parts "$parts_json" \
		'{
			system_instruction: { parts: [{ text: $system }] },
			contents: [{ parts: $parts }],
			generationConfig: {
				thinkingConfig: {
					thinkingLevel: "LOW"
				},
				temperature: 0.6,
				maxOutputTokens: 4096
			}
		}')

	log "gemini_correct: system_instruction='${system_instruction}'"
	log "gemini_correct: text='${raw_text}'"
	local response http_code
	response=$(curl -s -w '\n%{http_code}' --max-time 30 \
		"https://generativelanguage.googleapis.com/v1beta/models/gemini-3-flash-preview:generateContent?key=${gemini_key}" \
		-H 'Content-Type: application/json' \
		-d "$payload" 2>&1)

	http_code=$(echo "$response" | tail -1)
	response=$(echo "$response" | sed '$d')

	log "gemini_correct: http_code=${http_code}"
	if [ "$http_code" != "200" ]; then
		log "gemini_correct: error response: ${response}"
		echo "$raw_text"
		return
	fi

	local corrected
	corrected=$(echo "$response" | jq -r '.candidates[0].content.parts[0].text // empty')

	# Sanity check: if empty or 3x+ longer than input, fall back to raw
	if [ -z "$corrected" ]; then
		log "gemini_correct: empty extracted text, raw response: ${response}"
		echo "$raw_text"
		return
	fi

	log "gemini_correct: corrected='${corrected}'"
	echo "$corrected"
}

transcribe() {
	log "transcribe: start (correct=$CORRECT, context=$CONTEXT)"
	notify-send "VTT" "Transcribing..." --icon=accessories-text-editor --urgency=low --expire-time=2000

	log "transcribe: running whisper-cli"
	text=$(whisper-cli --model "$MODEL" --file "$AUDIOFILE" --no-timestamps --output-txt 2>/dev/null | tail -1)
	log "transcribe: whisper output='$text'"

	if [ -n "$text" ]; then
		if [ "$CORRECT" = true ]; then
			local context=""
			if [ "$CONTEXT" = true ]; then
				log "transcribe: gathering context"
				context=$(get_context)
			fi
			log "transcribe: running gemini correction"
			text=$(gemini_correct "$text" "$context")
		fi

		ydotool type -d 1 -H 1 -- "$text"
		ydotool key 28:1 28:0
		notify-send "VTT" "Typed: ${text:0:50}..." --icon=dialog-information --urgency=low --expire-time=2000
	else
		log "transcribe: no speech detected"
		notify-send "VTT" "No speech detected" --icon=dialog-warning --urgency=low --expire-time=2000
	fi

	rm -f "$AUDIOFILE"
}

start_recording() {
	log "start_recording: begin"
	notify-send "VTT" "Recording..." --icon=audio-input-microphone --urgency=low --expire-time=2000

	rec "$AUDIOFILE" silence 1 0.1 4% 1 1.0 4% &
	local rec_pid=$!
	echo $rec_pid >"$PIDFILE"
	log "start_recording: rec pid=$rec_pid"
	wait $rec_pid || true

	log "start_recording: rec finished"
	# if PIDFILE was removed by stop_and_transcribe, it's handling transcription
	if [ ! -f "$PIDFILE" ]; then
		log "start_recording: pidfile gone, stop_and_transcribe is handling it"
		return
	fi
	rm -f "$PIDFILE"
	transcribe
}

stop_and_transcribe() {
	local pid
	pid=$(cat "$PIDFILE")
	rm -f "$PIDFILE"
	log "stop_and_transcribe: sending SIGINT to rec (pid=$pid)"
	kill -INT "$pid" 2>/dev/null || true
	# give rec time to flush and close the WAV file
	sleep 0.5
	transcribe
}

if [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
	log "toggle: stopping existing recording"
	stop_and_transcribe
else
	log "toggle: starting new recording"
	rm -f "$PIDFILE" "$AUDIOFILE"
	start_recording
fi
