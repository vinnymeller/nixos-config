#!/usr/bin/env bash

CHROME_VERSION="google-chrome"
CHROME_EXECUTABLE="google-chrome-stable"

if [ -z "$CHROME_VERSION" ]; then
	echo "unable to find Chrome version"
	exit 1
fi

CHROME_USER_DATA_DIR="$HOME/.config/$CHROME_VERSION"
CHROME_USER_DATA_DIR_X11="$HOME/.config/$CHROME_VERSION-x11"

if [ ! -d "$CHROME_USER_DATA_DIR" ]; then
	echo "unable to find Chrome user data dir"
	exit 1
fi

DATA=$(
	python <<END
import json
with open("$CHROME_USER_DATA_DIR/Local State") as f:
    data = json.load(f)

for profile in data["profile"]["info_cache"]:
    print("%s_____%s" % (profile, data["profile"]["info_cache"][profile]["name"]))
END
)

declare -A profiles=()
while read -r line; do
	PROFILE="${line%_____*}"
	NAME="${line#*_____}"
	profiles["$NAME"]="$PROFILE"
done <<<"$DATA"

if [ "$#" -eq 0 ]; then
	for profile in "${!profiles[@]}"; do
		echo "$profile"
		echo "$profile (X11)"
	done
else
	NAME="$*"
	X11_FLAGS=(
		"--ozone-platform=x11"
		"--use-angle=vulkan"
		"--enable-features=TouchpadOverscrollHistoryNavigation,Vulkan,VulkanFromANGLE,DefaultANGLEVulkan,VaapiIgnoreDriverChecks,VaapiVideoDecoder,UseMultiPlaneFormatForHardwareVideo,VaapiVideoEncoder"
		"--force-device-scale-factor=1.5"
	)

	if [[ "$NAME" == *" (X11)" ]]; then
		NAME="${NAME% (X11)}"
		mkdir -p "$CHROME_USER_DATA_DIR_X11/${profiles[$NAME]}"
		exec $CHROME_EXECUTABLE --user-data-dir="$CHROME_USER_DATA_DIR_X11" "${X11_FLAGS[@]}" >/dev/null 2>&1
	else
		exec $CHROME_EXECUTABLE --profile-directory="${profiles[$NAME]}" >/dev/null 2>&1
	fi
fi
