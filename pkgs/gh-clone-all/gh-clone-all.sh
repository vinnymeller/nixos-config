#!/usr/bin/env bash

REPO_LIST=$(gh repo list --json nameWithOwner --jq '.[] | .nameWithOwner' --limit 99999)
DEV_DIR="$HOME/dev"

for REPO in $REPO_LIST; do
    REPO_DIR="$DEV_DIR/$REPO"
    if [ ! -d "$REPO_DIR" ]; then
        gh repo clone "$REPO" "$REPO_DIR"
    fi
done


