#!/usr/bin/env bash
# ------------------------------------------------------------------
# pomodoro-skip.sh – Skip button for Pomodoro timer
#
# Always visible - can skip even while running
# ------------------------------------------------------------------

set -euo pipefail

STATE_FILE="/tmp/waybar_pomodoro_state"

# Handle click
if [ "${1:-}" = "skip" ]; then
    /home/bjorn/.config/waybar/scripts/pomodoro.sh skip
    exit 0
fi

# Always show skip button
if [ -f "$STATE_FILE" ]; then
    state=$(cat "$STATE_FILE")
    if [ "$state" = "stopped" ]; then
        echo "{\"text\":\"▶▶\",\"tooltip\":\"Skip to next phase\",\"class\":\"paused\"}"
    else
        echo "{\"text\":\"▶▶\",\"tooltip\":\"Skip to next phase\",\"class\":\"running\"}"
    fi
else
    echo "{\"text\":\"▶▶\",\"tooltip\":\"Skip to next phase\",\"class\":\"stopped\"}"
fi
