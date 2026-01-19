#!/usr/bin/env bash
# ------------------------------------------------------------------
# spotify-record-icon.sh – Recording indicator icon
#
# Shows ⏺ when recording is active and Spotify is playing
# ------------------------------------------------------------------

set -euo pipefail

RECORDING_ENABLED_FILE="/tmp/waybar-spotify-recording-enabled"

# Check if recording is enabled
if [ ! -f "$RECORDING_ENABLED_FILE" ] || [ "$(cat "$RECORDING_ENABLED_FILE")" != "1" ]; then
    echo "{\"text\":\"\",\"tooltip\":\"\",\"class\":\"hidden\"}"
    exit 0
fi

# Check if Spotify is running
if ! playerctl -p spotify status &>/dev/null; then
    echo "{\"text\":\"\",\"tooltip\":\"\",\"class\":\"hidden\"}"
    exit 0
fi

# Get playback status
status=$(playerctl -p spotify status 2>/dev/null || echo "Stopped")

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
