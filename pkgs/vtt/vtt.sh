#!/usr/bin/env bash

MODEL="@MODEL_PATH@"
PIDFILE="/tmp/vtt.pid"
AUDIOFILE="/tmp/vtt.wav"

transcribe() {
	notify-send "VTT" "Transcribing..." --icon=accessories-text-editor --urgency=low --expire-time=2000

	text=$(whisper-cli --model "$MODEL" --file "$AUDIOFILE" --no-timestamps --output-txt 2>/dev/null | tail -1)

	if [ -n "$text" ]; then
		wtype "$text"
		wtype -k Return
		notify-send "VTT" "Typed: ${text:0:50}..." --icon=dialog-information --urgency=low --expire-time=2000
	else
		notify-send "VTT" "No speech detected" --icon=dialog-warning --urgency=low --expire-time=2000
	fi

	rm -f "$AUDIOFILE"
}

start_recording() {
	echo $$ >"$PIDFILE"
	notify-send "VTT" "Recording..." --icon=audio-input-microphone --urgency=low --expire-time=2000

	# record until silence detected (1s of silence at 10% threshold)
	rec "$AUDIOFILE" silence 1 0.1 10% 1 1.0 10%

	rm -f "$PIDFILE"
	transcribe
}

stop_and_transcribe() {
	kill "$(cat "$PIDFILE")" 2>/dev/null || true
	# the killed start_recording process won't reach transcribe,
	# so we need to wait for rec to flush and transcribe here
	sleep 0.2
	rm -f "$PIDFILE"
	transcribe
}

# toggle: if running, stop and transcribe; otherwise start
if [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
	stop_and_transcribe
else
	rm -f "$PIDFILE" "$AUDIOFILE"
	start_recording
fi
