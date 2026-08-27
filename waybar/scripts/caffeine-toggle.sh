#!/usr/bin/env bash
# ------------------------------------------------------------------
# caffeine-toggle.sh – Toggle caffeine mode (prevent sleep/screen off)
#
# Kills or restarts hypridle to prevent the system from going to sleep
# or turning off monitors.
# ------------------------------------------------------------------

set -euo pipefail

STATE_FILE="/tmp/waybar-caffeine-enabled"

# Check if hypridle is running (caffeine OFF means hypridle is running)
is_caffeine_active() {
    ! pgrep -x hypridle >/dev/null
}

# Handle toggle command
if [ "${1:-}" = "toggle" ]; then
    if is_caffeine_active; then
        # Caffeine is on (hypridle is dead), restart hypridle
        uwsm-app -- hypridle >/dev/null 2>&1 &
        echo "0" > "$STATE_FILE"
        notify-send "Caffeine" "Disabled – system will sleep normally" -i preferences-desktop-screensaver
    else
        # Caffeine is off (hypridle is running), kill it
        pkill -x hypridle || true
        echo "1" > "$STATE_FILE"
        notify-send "Caffeine" "Enabled – system will stay awake" -i caffeine
    fi

    # Force refresh of caffeine module
    pkill -SIGRTMIN+18 waybar

    exit 0
fi

# Display current state
if is_caffeine_active; then
    echo "{\"text\":\"󰅶\",\"tooltip\":\"Caffeine: ON\\nSystem will stay awake\\nClick to disable\",\"class\":\"caffeine-enabled\"}"
else
    echo "{\"text\":\"󰅶\",\"tooltip\":\"Caffeine: OFF\\nSystem will sleep normally\\nClick to enable\",\"class\":\"caffeine-disabled\"}"
fi
