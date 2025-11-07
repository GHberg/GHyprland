#!/usr/bin/env bash
# ------------------------------------------------------------------
# spotify-play.sh – Play/Pause button
# ------------------------------------------------------------------

set -euo pipefail

# Handle click
if [ "${1:-}" = "toggle" ]; then
    playerctl -p spotify play-pause 2>/dev/null
    exit 0
fi

# Check if Spotify is running
if ! playerctl -p spotify status &>/dev/null; then
    echo "{\"text\":\"\",\"tooltip\":\"\",\"class\":\"hidden\"}"
    exit 0
fi

# Get status to show correct icon
status=$(playerctl -p spotify status 2>/dev/null || echo "Stopped")

if [ "$status" = "Playing" ]; then
    echo "{\"text\":\"⏸\",\"tooltip\":\"Pause\",\"class\":\"control playing\"}"
else
    echo "{\"text\":\"▶\",\"tooltip\":\"Play\",\"class\":\"control paused\"}"
fi
