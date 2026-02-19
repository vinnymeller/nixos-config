#!/usr/bin/env bash

MODEL="@MODEL_PATH@"
PIDFILE="/tmp/vtt.pid"
AUDIOFILE="/tmp/vtt.wav"
LOGFILE="/tmp/vtt.log"

log() {
	echo "[$(date '+%H:%M:%S.%3N')] $*" >>"$LOGFILE"
}

transcribe() {
	log "transcribe: start"
	notify-send "VTT" "Transcribing..." --icon=accessories-text-editor --urgency=low --expire-time=2000

	log "transcribe: running whisper-cli"
	text=$(whisper-cli --model "$MODEL" --file "$AUDIOFILE" --no-timestamps --output-txt 2>/dev/null | tail -1)
	log "transcribe: whisper output='$text'"

	if [ -n "$text" ]; then
		wtype "$text"
		wtype -k Return
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
