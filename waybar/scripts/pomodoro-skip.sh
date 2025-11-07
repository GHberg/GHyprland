#!/usr/bin/env bash
# ------------------------------------------------------------------
# pomodoro-skip.sh – Skip button for Pomodoro timer
#
# Only shows when timer is paused
# ------------------------------------------------------------------

set -euo pipefail

STATE_FILE="/tmp/waybar_pomodoro_state"

# Handle click
if [ "${1:-}" = "skip" ]; then
    /home/bjorn/.config/waybar/scripts/pomodoro.sh skip
    exit 0
fi

# Check if timer is paused
if [ -f "$STATE_FILE" ]; then
    state=$(cat "$STATE_FILE")
    if [ "$state" = "stopped" ]; then
        # Show skip button when paused (with left padding)
        echo "{\"text\":\" ▶▶\",\"tooltip\":\"Skip to next phase\",\"class\":\"paused\"}"
    else
        # Hide when running
        echo "{\"text\":\"\",\"tooltip\":\"\",\"class\":\"hidden\"}"
    fi
else
    # Hide by default
    echo "{\"text\":\"\",\"tooltip\":\"\",\"class\":\"hidden\"}"
fi
