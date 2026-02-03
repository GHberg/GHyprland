#!/usr/bin/env bash
# ------------------------------------------------------------------
# spotify-icon.sh – Music player icon with toggle functionality
# ------------------------------------------------------------------

set -euo pipefail

# shellcheck source=music-player-detect.sh
. "$(dirname "$0")/music-player-detect.sh"

STATE_FILE="/tmp/waybar-spotify-state"

# Handle toggle command
if [ "${1:-}" = "toggle" ]; then
    if [ -f "$STATE_FILE" ]; then
        current_state=$(cat "$STATE_FILE")
        if [ "$current_state" = "expanded" ]; then
            echo "collapsed" > "$STATE_FILE"
        else
            echo "expanded" > "$STATE_FILE"
        fi
    fi
    # Force immediate refresh of all Spotify modules
    pkill -SIGRTMIN+8 waybar  # spotify-icon
    pkill -SIGRTMIN+9 waybar  # spotify info
    pkill -SIGRTMIN+10 waybar # spotify-prev
    pkill -SIGRTMIN+11 waybar # spotify-play
    pkill -SIGRTMIN+12 waybar # spotify-next
    pkill -SIGRTMIN+13 waybar # spotify-record-toggle
    pkill -SIGRTMIN+14 waybar # spotify-record-icon
    exit 0
fi

# Check if any supported player is running
PLAYER=$(get_active_player)
if [ -z "$PLAYER" ]; then
    # Clean up state file when no player is running
    rm -f "$STATE_FILE"
    echo "{\"text\":\"\",\"tooltip\":\"\",\"class\":\"hidden\"}"
    exit 0
fi

# Initialize state file to expanded if player just started
if [ ! -f "$STATE_FILE" ]; then
    echo "expanded" > "$STATE_FILE"
fi

# Player-specific icon
player_icon=$(get_player_icon "$PLAYER")

# Read current state for tooltip
state=$(cat "$STATE_FILE" 2>/dev/null || echo "expanded")
if [ "$state" = "expanded" ]; then
    tooltip="Click to collapse"
else
    tooltip="Click to expand"
fi

# Output JSON with icon and tooltip
echo "{\"text\":\"$player_icon\",\"tooltip\":\"$tooltip\",\"class\":\"icon\"}"
