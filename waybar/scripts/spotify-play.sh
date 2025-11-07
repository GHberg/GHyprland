#!/usr/bin/env bash
# ------------------------------------------------------------------
# spotify-play.sh – Play/Pause button
# ------------------------------------------------------------------

set -euo pipefail

STATE_FILE="/tmp/waybar-spotify-state"

# Handle click action for play/pause toggle
if [ "${1:-}" = "toggle" ]; then
    playerctl -p spotify play-pause 2>/dev/null
    exit 0
fi

# Check if Spotify is running
if ! playerctl -p spotify status &>/dev/null; then
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

# Get status to show correct icon
status=$(playerctl -p spotify status 2>/dev/null || echo "Stopped")

if [ "$status" = "Playing" ]; then
    echo "{\"text\":\"⏸\",\"tooltip\":\"Pause\",\"class\":\"control playing\"}"
else
    echo "{\"text\":\"▶\",\"tooltip\":\"Play\",\"class\":\"control paused\"}"
fi
