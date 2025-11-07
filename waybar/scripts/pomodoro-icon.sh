#!/usr/bin/env bash
# ------------------------------------------------------------------
# pomodoro-icon.sh – Pomodoro toggle icon (shows current phase)
# ------------------------------------------------------------------

set -euo pipefail

# State files
PHASE_FILE="/tmp/waybar_pomodoro_phase"
COLLAPSE_STATE="/tmp/waybar_pomodoro_collapsed"

# Handle toggle command
if [ "${1:-}" = "toggle" ]; then
    if [ -f "$COLLAPSE_STATE" ]; then
        current=$(cat "$COLLAPSE_STATE")
        if [ "$current" = "expanded" ]; then
            echo "collapsed" > "$COLLAPSE_STATE"
        else
            echo "expanded" > "$COLLAPSE_STATE"
        fi
    else
        echo "collapsed" > "$COLLAPSE_STATE"
    fi
    # Force immediate refresh of all Pomodoro modules
    pkill -SIGRTMIN+13 waybar  # pomodoro-icon
    pkill -SIGRTMIN+14 waybar  # pomodoro timer
    pkill -SIGRTMIN+15 waybar  # pomodoro-play
    pkill -SIGRTMIN+16 waybar  # pomodoro-skip
    exit 0
fi

# Initialize files
if [ ! -f "$PHASE_FILE" ]; then
    echo "work" > "$PHASE_FILE"
fi

if [ ! -f "$COLLAPSE_STATE" ]; then
    echo "expanded" > "$COLLAPSE_STATE"
fi

# Get current phase
phase=$(cat "$PHASE_FILE")

# Choose icon based on phase
case "$phase" in
    work)
        icon="🍅"
        ;;
    short_break)
        icon="🧋"
        ;;
    long_break)
        icon="🥨"
        ;;
esac

# Read collapse state for tooltip
state=$(cat "$COLLAPSE_STATE" 2>/dev/null || echo "expanded")
if [ "$state" = "expanded" ]; then
    tooltip="Click to collapse"
else
    tooltip="Click to expand"
fi

# Output JSON
echo "{\"text\":\"$icon\",\"tooltip\":\"$tooltip\",\"class\":\"icon\"}"
