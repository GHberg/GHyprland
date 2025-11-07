#!/usr/bin/env bash
# ------------------------------------------------------------------
# spotify-prev.sh – Previous track button
# ------------------------------------------------------------------

set -euo pipefail

STATE_FILE="/tmp/waybar-spotify-state"

# Handle click action
if [ "${1:-}" = "prev" ]; then
    playerctl -p spotify previous 2>/dev/null
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

# Show button when Spotify is active and expanded
echo "{\"text\":\"⏮\",\"tooltip\":\"Previous track\",\"class\":\"control\"}"
