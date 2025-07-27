#!/usr/bin/env bash

# Check for the required argument
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <filename>"
    exit 1
fi

FILENAME="$1"
CURRENT_DIR="$(pwd)"

while [[ "$CURRENT_DIR" != "" && ! -e "$CURRENT_DIR/$FILENAME" ]]; do
    CURRENT_DIR="${CURRENT_DIR%/*}"
done

if [ -e "$CURRENT_DIR/$FILENAME" ]; then
    echo "$CURRENT_DIR/$FILENAME"
    exit 0
else
    exit 1
fi

