#!/usr/bin/env bash
# ------------------------------------------------------------------
# pomodoro-skip.sh – Skip button for Pomodoro timer
# ------------------------------------------------------------------

set -euo pipefail

STATE_FILE="/tmp/waybar_pomodoro_state"
COLLAPSE_STATE="/tmp/waybar_pomodoro_collapsed"

# Handle click action
if [ "${1:-}" = "skip" ]; then
    /home/bjorn/.config/waybar/scripts/pomodoro.sh skip
    exit 0
fi

# Initialize if files don't exist
if [ ! -f "$STATE_FILE" ]; then
    echo "stopped" > "$STATE_FILE"
fi

if [ ! -f "$COLLAPSE_STATE" ]; then
    echo "expanded" > "$COLLAPSE_STATE"
fi

# Check if collapsed
collapse_state=$(cat "$COLLAPSE_STATE")
if [ "$collapse_state" = "collapsed" ]; then
    echo "{\"text\":\"\",\"tooltip\":\"\",\"class\":\"hidden\"}"
    exit 0
fi

# Show skip button when expanded
state=$(cat "$STATE_FILE")
if [ "$state" = "stopped" ]; then
    echo "{\"text\":\"▶▶\",\"tooltip\":\"Skip to next phase\",\"class\":\"control paused\"}"
else
    echo "{\"text\":\"▶▶\",\"tooltip\":\"Skip to next phase\",\"class\":\"control running\"}"
fi
