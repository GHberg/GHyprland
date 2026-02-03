#!/usr/bin/env bash
# ------------------------------------------------------------------
# spotify-record-toggle.sh – Toggle music recording on/off
#
# Manages the recording daemon and system clock settings
# ------------------------------------------------------------------

set -euo pipefail

# shellcheck source=music-player-detect.sh
. "$(dirname "$0")/music-player-detect.sh"

RECORDING_ENABLED_FILE="/tmp/waybar-spotify-recording-enabled"
DAEMON_PID_FILE="/tmp/waybar-spotify-record-daemon-pid"
DAEMON_SCRIPT="$HOME/.config/waybar/scripts/spotify-record-daemon.sh"

# Handle toggle command
if [ "${1:-}" = "toggle" ]; then
    PLAYER=$(get_active_player)
    player_name=$(get_player_display_name "$PLAYER")

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
        notify-send "$player_name Recording" "Recording disabled" -i media-record
    else
        # Enable recording
        echo "1" > "$RECORDING_ENABLED_FILE"

        # Detect the player's native sample rate for bit-perfect capture
        local sample_rate
        sample_rate=$(get_player_sample_rate "$PLAYER")

        # Force system clock to match the player's native rate (avoids resampling)
        pw-metadata -n settings 0 clock.force-rate "$sample_rate"

        # Start daemon
        "$DAEMON_SCRIPT" &
        daemon_pid=$!
        echo "$daemon_pid" > "$DAEMON_PID_FILE"

        # Notify user
        notify-send "$player_name Recording" "Recording enabled\nQuality: ${sample_rate} Hz, 32-bit float" -i media-record
    fi

    # Force refresh of recording modules and spotify info (for tooltip update)
    pkill -SIGRTMIN+9 waybar   # spotify info (tooltip)
    pkill -SIGRTMIN+13 waybar  # spotify-record-toggle
    pkill -SIGRTMIN+14 waybar  # spotify-record-icon

    exit 0
fi

STATE_FILE="/tmp/waybar-spotify-state"

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

# Display current state
if [ -f "$RECORDING_ENABLED_FILE" ] && [ "$(cat "$RECORDING_ENABLED_FILE")" = "1" ]; then
    # Recording enabled
    echo "{\"text\":\"REC\",\"tooltip\":\"Recording enabled\\nClick to disable\",\"class\":\"recording-enabled\"}"
else
    # Recording disabled
    echo "{\"text\":\"REC\",\"tooltip\":\"Recording disabled\\nClick to enable\",\"class\":\"recording-disabled\"}"
fi
