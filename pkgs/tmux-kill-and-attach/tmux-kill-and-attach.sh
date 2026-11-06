#!/usr/bin/env bash

ORIG_SESS="$TWM_NAME"
tmux switch-client -l || tmux switch-client -n || tmux switch-client -p
tmux kill-session -t "$ORIG_SESS"
