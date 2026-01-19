#!/usr/bin/env bash
# ------------------------------------------------------------------
# spotify-record-toggle.sh – Toggle Spotify recording on/off
#
# Manages the recording daemon and system clock settings
# ------------------------------------------------------------------

set -euo pipefail

RECORDING_ENABLED_FILE="/tmp/waybar-spotify-recording-enabled"
DAEMON_PID_FILE="/tmp/waybar-spotify-record-daemon-pid"
DAEMON_SCRIPT="$HOME/.config/waybar/scripts/spotify-record-daemon.sh"

# Handle toggle command
if [ "${1:-}" = "toggle" ]; then
    if [ -f "$RECORDING_ENABLED_FILE" ] && [ "$(cat "$RECORDING_ENABLED_FILE")" = "1" ]; then
        # Disable recording
        echo "0" > "$RECORDING_ENABLED_FILE"

        # Kill daemon
        if [ -f "$DAEMON_PID_FILE" ]; then
            daemon_pid=$(cat "$DAEMON_PID_FILE")
            if kill -0 "$daemon_pid" 2>/dev/null; then
                kill "$daemon_pid" 2>/dev/null || true
                wait "$daemon_pid" 2>/dev/null || true
            fi
            rm -f "$DAEMON_PID_FILE"
        fi

        # Reset PipeWire (restores default clock)
        systemctl --user restart pipewire

        # Notify user
        notify-send "Spotify Recording" "Recording disabled" -i media-record
    else
        # Enable recording
        echo "1" > "$RECORDING_ENABLED_FILE"

        # Set system clock to 44.1 kHz (CRITICAL for bit-perfect capture)
        pw-metadata -n settings 0 clock.force-rate 44100

        # Start daemon
        "$DAEMON_SCRIPT" &
        daemon_pid=$!
        echo "$daemon_pid" > "$DAEMON_PID_FILE"

        # Notify user
        notify-send "Spotify Recording" "Recording enabled\nQuality: 44.1 kHz, 32-bit float" -i media-record
    fi

    # Force refresh of recording modules and spotify info (for tooltip update)
    pkill -SIGRTMIN+9 waybar   # spotify info (tooltip)
    pkill -SIGRTMIN+13 waybar  # spotify-record-toggle
    pkill -SIGRTMIN+14 waybar  # spotify-record-icon

    exit 0
fi

# Display current state
if [ -f "$RECORDING_ENABLED_FILE" ] && [ "$(cat "$RECORDING_ENABLED_FILE")" = "1" ]; then
    # Recording enabled
    echo "{\"text\":\"REC\",\"tooltip\":\"Recording enabled\\nClick to disable\",\"class\":\"recording-enabled\"}"
else
    # Recording disabled
    echo "{\"text\":\"REC\",\"tooltip\":\"Recording disabled\\nClick to enable\",\"class\":\"recording-disabled\"}"
fi
