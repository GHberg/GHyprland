#!/usr/bin/env bash
# ------------------------------------------------------------------
# spotify-play.sh – Play/Pause button
# ------------------------------------------------------------------

set -euo pipefail

# shellcheck source=music-player-detect.sh
. "$(dirname "$0")/music-player-detect.sh"

STATE_FILE="/tmp/waybar-spotify-state"

# Handle click action for play/pause toggle
if [ "${1:-}" = "toggle" ]; then
    PLAYER=$(get_active_player)
    [ -n "$PLAYER" ] && playerctl -p "$PLAYER" play-pause 2>/dev/null
    exit 0
fi

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

# Get status to show correct icon
status=$(playerctl -p "$PLAYER" status 2>/dev/null || echo "Stopped")

if [ "$status" = "Playing" ]; then
    echo "{\"text\":\"⏸\",\"tooltip\":\"Pause\",\"class\":\"control playing\"}"
else
    echo "{\"text\":\"▶\",\"tooltip\":\"Play\",\"class\":\"control paused\"}"
fi
