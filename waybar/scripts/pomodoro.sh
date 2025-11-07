#!/usr/bin/env bash
# ------------------------------------------------------------------
# pomodoro.sh – Waybar Pomodoro Timer Module
#
# Left click: Start/Pause
# Right click: Reset
# Middle click: Skip to next phase
# ------------------------------------------------------------------

set -euo pipefail

# Configuration
WORK_TIME=1500        # 25 minutes in seconds
SHORT_BREAK=300       # 5 minutes
LONG_BREAK=900        # 15 minutes
POMODOROS_UNTIL_LONG=4

# State files
STATE_FILE="/tmp/waybar_pomodoro_state"
TIME_FILE="/tmp/waybar_pomodoro_time"
COUNT_FILE="/tmp/waybar_pomodoro_count"
PHASE_FILE="/tmp/waybar_pomodoro_phase"
NOTIF_15_FILE="/tmp/waybar_pomodoro_notif_15"
NOTIF_5_FILE="/tmp/waybar_pomodoro_notif_5"

# Initialize if files don't exist
if [ ! -f "$STATE_FILE" ]; then
    echo "stopped" > "$STATE_FILE"
fi

if [ ! -f "$TIME_FILE" ]; then
    echo "$WORK_TIME" > "$TIME_FILE"
fi

if [ ! -f "$COUNT_FILE" ]; then
    echo "0" > "$COUNT_FILE"
fi

if [ ! -f "$PHASE_FILE" ]; then
    echo "work" > "$PHASE_FILE"
fi

# Handle clicks
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
    exit 0
fi

if [ "${1:-}" = "reset" ]; then
    echo "stopped" > "$STATE_FILE"
    echo "$WORK_TIME" > "$TIME_FILE"
    echo "0" > "$COUNT_FILE"
    echo "work" > "$PHASE_FILE"
    rm -f "$NOTIF_15_FILE" "$NOTIF_5_FILE"
    notify-send "🍅 Pomodoro" "Timer reset" -t 2000
    exit 0
fi

if [ "${1:-}" = "skip" ]; then
    phase=$(cat "$PHASE_FILE")
    count=$(cat "$COUNT_FILE")
    current_state=$(cat "$STATE_FILE")

    if [ "$phase" = "work" ]; then
        count=$((count + 1))
        echo "$count" > "$COUNT_FILE"

        if [ $((count % POMODOROS_UNTIL_LONG)) -eq 0 ]; then
            echo "long_break" > "$PHASE_FILE"
            echo "$LONG_BREAK" > "$TIME_FILE"
            notify-send "🍅 Pomodoro" "Skipped to long break! (15 min)" -t 3000
        else
            echo "short_break" > "$PHASE_FILE"
            echo "$SHORT_BREAK" > "$TIME_FILE"
            notify-send "🍅 Pomodoro" "Skipped to short break! (5 min)" -t 3000
        fi
    else
        echo "work" > "$PHASE_FILE"
        echo "$WORK_TIME" > "$TIME_FILE"
        notify-send "🍅 Pomodoro" "Skipped to work phase! (25 min)" -t 3000
    fi
    rm -f "$NOTIF_15_FILE" "$NOTIF_5_FILE"

    # If running, keep running; if stopped, start automatically
    if [ "$current_state" = "stopped" ]; then
        echo "running" > "$STATE_FILE"
    fi
    exit 0
fi

# Update timer
state=$(cat "$STATE_FILE")
time_left=$(cat "$TIME_FILE")
phase=$(cat "$PHASE_FILE")
count=$(cat "$COUNT_FILE")

if [ "$state" = "running" ] && [ "$time_left" -gt 0 ]; then
    time_left=$((time_left - 1))
    echo "$time_left" > "$TIME_FILE"

    # Send notification at 15 minutes remaining (only for work sessions)
    if [ "$time_left" -eq 900 ] && [ "$phase" = "work" ] && [ ! -f "$NOTIF_15_FILE" ]; then
        notify-send "🍅 Pomodoro" "15 minutes remaining!" -t 3000
        touch "$NOTIF_15_FILE"
    fi

    # Send notification at 5 minutes remaining (for all phases)
    if [ "$time_left" -eq 300 ] && [ ! -f "$NOTIF_5_FILE" ]; then
        notify-send "🍅 Pomodoro" "5 minutes remaining!" -t 3000
        touch "$NOTIF_5_FILE"
    fi

    # Check if time is up
    if [ "$time_left" -eq 0 ]; then
        if [ "$phase" = "work" ]; then
            count=$((count + 1))
            echo "$count" > "$COUNT_FILE"

            if [ $((count % POMODOROS_UNTIL_LONG)) -eq 0 ]; then
                echo "long_break" > "$PHASE_FILE"
                echo "$LONG_BREAK" > "$TIME_FILE"
                notify-send "🍅 Pomodoro Complete!" "Great work! Take a long break (15 min)" -u critical -t 5000
            else
                echo "short_break" > "$PHASE_FILE"
                echo "$SHORT_BREAK" > "$TIME_FILE"
                notify-send "🍅 Pomodoro Complete!" "Time for a short break (5 min)" -u critical -t 5000
            fi
        else
            echo "work" > "$PHASE_FILE"
            echo "$WORK_TIME" > "$TIME_FILE"
            notify-send "🍅 Break Over!" "Back to work! (25 min)" -u critical -t 5000
        fi
        rm -f "$NOTIF_15_FILE" "$NOTIF_5_FILE"
        echo "stopped" > "$STATE_FILE"
    fi
fi

# Format time for display
minutes=$((time_left / 60))
seconds=$((time_left % 60))
time_display=$(printf "%02d:%02d" $minutes $seconds)

# Choose icon based on phase and state
if [ "$state" = "stopped" ]; then
    icon="⏸"
else
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
fi

# Build tooltip
phase_name=""
case "$phase" in
    work)
        phase_name="Work Session"
        ;;
    short_break)
        phase_name="Short Break"
        ;;
    long_break)
        phase_name="Long Break"
        ;;
esac

tooltip="🍅 Pomodoro Timer\\n\\n"
tooltip+="Phase: $phase_name\\n"
tooltip+="Status: ${state^}\\n"
tooltip+="Time left: $time_display\\n"
tooltip+="Completed: $count pomodoros\\n\\n"
tooltip+="Left click: Start/Pause\\n"
tooltip+="Right click: Reset"

# Output JSON with phase and state as classes
if [ "$state" = "stopped" ]; then
    echo "{\"text\":\"$icon $time_display\",\"tooltip\":\"$tooltip\",\"class\":\"$phase paused\"}"
else
    echo "{\"text\":\"$icon $time_display\",\"tooltip\":\"$tooltip\",\"class\":\"$phase\"}"
fi
