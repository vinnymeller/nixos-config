#!/usr/bin/env bash

ORIG_SESS="$TWM_NAME"
tmux switch -l || tmux switch -n || tmux switch -p
tmux kill-session -t "$ORIG_SESS"
