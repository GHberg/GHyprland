#!/usr/bin/env bash
# ------------------------------------------------------------------
# spotify-next.sh – Next track button
# ------------------------------------------------------------------

set -euo pipefail

# shellcheck source=music-player-detect.sh
. "$(dirname "$0")/music-player-detect.sh"

STATE_FILE="/tmp/waybar-spotify-state"

# Handle click action
if [ "${1:-}" = "next" ]; then
    PLAYER=$(get_active_player)
    [ -n "$PLAYER" ] && playerctl -p "$PLAYER" next 2>/dev/null
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

# Show button when player is active and expanded
echo "{\"text\":\"⏭\",\"tooltip\":\"Next track\",\"class\":\"control\"}"
