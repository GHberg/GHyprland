#!/usr/bin/env bash
# ------------------------------------------------------------------
# vinyl-toggle.sh – Toggle vinyl player loopback on/off
#
# Switches audio input between system (computer) and vinyl player
# ------------------------------------------------------------------

set -euo pipefail

MODULE_NAME="module-loopback"
SOURCE="alsa_input.usb-Sony_Corporation_PS-HX500-00.analog-stereo"
SINK="alsa_output.usb-iFi__by_AMR__iFi__by_AMR__HD_USB_Audio_0002-00.analog-stereo"
STATE_FILE="/tmp/waybar-vinyl-loopback-enabled"

# Check if loopback module is loaded
check_loopback() {
    pactl list modules short | grep -q "module-loopback" && \
    pactl list source-outputs | grep -q "$SOURCE"
}

# Handle toggle command
if [ "${1:-}" = "toggle" ]; then
    if check_loopback; then
        # Loopback is running, disable it
        # Find the loopback module ID
        MODULE_ID=$(pactl list modules short | grep "module-loopback" | awk '{print $1}' | tail -1)

        if [ -n "$MODULE_ID" ]; then
            pactl unload-module "$MODULE_ID" || true
        fi

        # Update state file
        echo "0" > "$STATE_FILE"

        # Notify user
        notify-send "Audio Input" "Switched to System Audio" -i audio-card
    else
        # Loopback is not running, enable it
        pactl load-module module-loopback source="$SOURCE" sink="$SINK" latency_msec=20

        # Update state file
        echo "1" > "$STATE_FILE"

        # Notify user
        notify-send "Audio Input" "Switched to Vinyl Player" -i media-optical
    fi

    # Force refresh of vinyl toggle module
    pkill -SIGRTMIN+17 waybar

    exit 0
fi

# Display current state
if check_loopback; then
    # Vinyl player active
    echo "{\"text\":\"󰽰\",\"tooltip\":\"Audio: Vinyl Player\\nClick to switch to System\",\"class\":\"vinyl-enabled\"}"
else
    # System audio active
    echo "{\"text\":\"󰽰\",\"tooltip\":\"Audio: System\\nClick to switch to Vinyl Player\",\"class\":\"vinyl-disabled\"}"
fi
