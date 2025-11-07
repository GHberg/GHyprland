#!/usr/bin/env bash
# ------------------------------------------------------------------
# cpu.sh – Waybar CPU utilisation module with rolling average
#
# Calculates 15-second rolling average (last 3 samples @ 5s interval)
# ------------------------------------------------------------------

set -euo pipefail

STATE_FILE="/tmp/waybar-system-metrics-state"

# Check if collapsed
if [ -f "$STATE_FILE" ]; then
    state=$(cat "$STATE_FILE")
    if [ "$state" = "collapsed" ]; then
        echo "{\"text\":\"\",\"tooltip\":\"\",\"class\":\"hidden\"}"
        exit 0
    fi
fi

# History file for rolling average
HISTORY_FILE="/tmp/waybar_cpu_history"

# Read current CPU usage from /proc/stat
get_cpu_usage() {
    read cpu user nice system idle iowait irq softirq steal guest < /proc/stat
    total_idle=$((idle + iowait))
    total=$((user + nice + system + idle + iowait + irq + softirq + steal))

    # Store current values
    echo "$total $total_idle"
}

# Read previous values if they exist
if [ -f "/tmp/waybar_cpu_prev" ]; then
    read prev_total prev_idle < "/tmp/waybar_cpu_prev"
    read total total_idle < <(get_cpu_usage)

    # Calculate current usage
    diff_total=$((total - prev_total))
    diff_idle=$((total_idle - prev_idle))

    if [ "$diff_total" -gt 0 ]; then
        current_usage=$(awk "BEGIN {printf \"%.0f\", 100 * ($diff_total - $diff_idle) / $diff_total}")
    else
        current_usage=0
    fi
else
    current_usage=0
fi

# Save current values for next run
get_cpu_usage > "/tmp/waybar_cpu_prev"

# Update history and calculate rolling average
if [ -f "$HISTORY_FILE" ]; then
    mapfile -t history < "$HISTORY_FILE"
else
    history=()
fi

# Add current reading
history+=("$current_usage")

# Keep only last 3 readings
if [ ${#history[@]} -gt 3 ]; then
    history=("${history[@]: -3}")
fi

# Save updated history
printf "%s\n" "${history[@]}" > "$HISTORY_FILE"

# Calculate average
sum=0
for val in "${history[@]}"; do
    sum=$(awk "BEGIN {printf \"%.0f\", $sum + $val}")
done
avg_usage=$(awk "BEGIN {printf \"%.0f\", $sum / ${#history[@]}}")

# Get top 5 CPU-consuming applications (aggregated by name)
# Disable pipefail temporarily to avoid SIGPIPE from head
set +o pipefail
top_processes=$(ps aux | awk 'NR>1 {
    # Extract basename from command path
    cmd = $11
    gsub(/^.*\//, "", cmd)

    # Handle /proc/self/exe (common for Electron apps)
    if (cmd == "exe") {
        # Try to extract app name from --user-data-dir argument
        for (i = 12; i <= NF; i++) {
            if ($i ~ /--user-data-dir=/) {
                match($i, /--user-data-dir=.*\/\.config\/([^\/]+)/, arr)
                if (arr[1] != "") {
                    cmd = arr[1]
                    break
                }
            }
            # Also check for app.asar path
            if ($i ~ /\.asar$/) {
                match($i, /\/([^\/]+)\/app\.asar/, arr)
                if (arr[1] != "") {
                    cmd = arr[1]
                    break
                }
            }
        }
    }

    # Aggregate CPU by application name
    cpu[cmd] += $3
}
END {
    # Sort by CPU usage and output top 5
    for (app in cpu) {
        printf "%s %.1f\n", app, cpu[app]
    }
}' | sort -k2 -rn 2>/dev/null | head -n 5 | awk '{$1 = toupper(substr($1,1,1)) tolower(substr($1,2)); printf "▸ %s %s%%\\n", $1, $2}')
set -o pipefail

# Build tooltip with top processes
tooltip="Top 5 CPU Usage:\\n${top_processes}"

# Emit JSON for Waybar
echo "{\"text\":\"$avg_usage\",\"tooltip\":\"$tooltip\"}"
