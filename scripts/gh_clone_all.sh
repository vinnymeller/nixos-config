#!/usr/bin/env bash

REPO_LIST=$(gh repo list --json nameWithOwner --jq '.[] | .nameWithOwner' --limit 99999)
DEV_DIR="$HOME/dev"

for REPO in $REPO_LIST; do
	gh repo clone "$REPO" "$DEV_DIR/$REPO"
done


