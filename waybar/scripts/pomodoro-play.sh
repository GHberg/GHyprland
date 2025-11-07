#!/usr/bin/env bash
# ------------------------------------------------------------------
# pomodoro-play.sh – Play/Pause button for Pomodoro
# ------------------------------------------------------------------

set -euo pipefail

# State files
STATE_FILE="/tmp/waybar_pomodoro_state"
COLLAPSE_STATE="/tmp/waybar_pomodoro_collapsed"
NOTIF_15_FILE="/tmp/waybar_pomodoro_notif_15"
NOTIF_5_FILE="/tmp/waybar_pomodoro_notif_5"

# Handle click action for play/pause toggle
if [ "${1:-}" = "toggle" ]; then
    state=$(cat "$STATE_FILE")
    if [ "$state" = "stopped" ]; then
        echo "running" > "$STATE_FILE"
        # Reset notification flags when starting
        rm -f "$NOTIF_15_FILE" "$NOTIF_5_FILE"
        notify-send "🍅 Pomodoro" "Timer started!" -t 2000
    else
        echo "stopped" > "$STATE_FILE"
        notify-send "🍅 Pomodoro" "Timer paused" -t 2000
    fi
    # Force immediate refresh
    pkill -SIGRTMIN+14 waybar  # pomodoro timer
    pkill -SIGRTMIN+15 waybar  # pomodoro-play (this)
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

# Get state to show correct icon
state=$(cat "$STATE_FILE")

if [ "$state" = "running" ]; then
    echo "{\"text\":\"⏸\",\"tooltip\":\"Pause\",\"class\":\"control playing\"}"
else
    echo "{\"text\":\"▶\",\"tooltip\":\"Play\",\"class\":\"control paused\"}"
fi
