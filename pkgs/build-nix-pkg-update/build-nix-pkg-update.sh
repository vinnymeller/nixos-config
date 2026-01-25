#!/usr/bin/env bash

if [ "$#" -ne 1 ]; then
	echo "Usage: $0 <package>"
	exit 1
fi

PACKAGE_NAME="$1"

pushd "$HOME/dev/vinnymeller/nixpkgs" || exit
git fetch r-ryantm "auto-update/$PACKAGE_NAME"
git checkout FETCH_HEAD
nix build .#"$PACKAGE_NAME"
