#!/usr/bin/env bash
# ------------------------------------------------------------------
# gpu-icon.sh – System metrics icon with toggle functionality
# Controls CPU, GPU, and RAM display (unified pill)
# ------------------------------------------------------------------

set -euo pipefail

STATE_FILE="/tmp/waybar-system-metrics-state"

# Handle toggle command
if [ "${1:-}" = "toggle" ]; then
    if [ -f "$STATE_FILE" ]; then
        current_state=$(cat "$STATE_FILE")
        if [ "$current_state" = "expanded" ]; then
            echo "collapsed" > "$STATE_FILE"
        else
            echo "expanded" > "$STATE_FILE"
        fi
    else
        echo "collapsed" > "$STATE_FILE"
    fi
    # Force immediate refresh of all system metric modules
    pkill -SIGRTMIN+2 waybar  # cpu
    pkill -SIGRTMIN+3 waybar  # gpu-icon
    pkill -SIGRTMIN+4 waybar  # gpu info
    pkill -SIGRTMIN+6 waybar  # ram
    exit 0
fi

# Initialize state file to expanded by default
if [ ! -f "$STATE_FILE" ]; then
    echo "expanded" > "$STATE_FILE"
fi

# GPU icon (nerd font) - used for unified system metrics
gpu_icon=$'\uf2db'  # nf-md-expansion_card

# Read current state for tooltip
state=$(cat "$STATE_FILE" 2>/dev/null || echo "expanded")
if [ "$state" = "expanded" ]; then
    tooltip="System Metrics\nClick to collapse"
else
    tooltip="System Metrics\nClick to expand"
fi

# Output JSON with icon and tooltip
echo "{\"text\":\"$gpu_icon\",\"tooltip\":\"$tooltip\",\"class\":\"icon\"}"
