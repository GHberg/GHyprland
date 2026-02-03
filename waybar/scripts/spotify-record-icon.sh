#!/usr/bin/env bash
# ------------------------------------------------------------------
# spotify-record-icon.sh – Recording indicator icon
#
# Shows ⏺ when recording is active and a music player is playing
# ------------------------------------------------------------------

set -euo pipefail

# shellcheck source=music-player-detect.sh
. "$(dirname "$0")/music-player-detect.sh"

RECORDING_ENABLED_FILE="/tmp/waybar-spotify-recording-enabled"
STATE_FILE="/tmp/waybar-spotify-state"

# Check if any supported player is running
PLAYER=$(get_active_player)
if [ -z "$PLAYER" ]; then
    echo "{\"text\":\"\",\"tooltip\":\"\",\"class\":\"hidden\"}"
    exit 0
fi

# Check if collapsed
if [ -f "$STATE_FILE" ]; then
    state=$(cat "$STATE_FILE")
    if [ "$state" = "collapsed" ]; then
        echo "{\"text\":\"\",\"tooltip\":\"\",\"class\":\"hidden\"}"
        exit 0
    fi
fi

# Check if recording is enabled
if [ ! -f "$RECORDING_ENABLED_FILE" ] || [ "$(cat "$RECORDING_ENABLED_FILE")" != "1" ]; then
    echo "{\"text\":\"\",\"tooltip\":\"\",\"class\":\"hidden\"}"
    exit 0
fi

# Get playback status
status=$(playerctl -p "$PLAYER" status 2>/dev/null || echo "Stopped")

case "$status" in
    Playing)
        # Show recording indicator
        echo "{\"text\":\"⏺\",\"tooltip\":\"Recording in progress\",\"class\":\"recording-active\"}"
        ;;
    Paused)
        # Show paused recording indicator
        echo "{\"text\":\"⏺\",\"tooltip\":\"Recording paused\",\"class\":\"recording-paused\"}"
        ;;
    *)
        # Not playing, hide
        echo "{\"text\":\"\",\"tooltip\":\"\",\"class\":\"hidden\"}"
        ;;
esac
