#!/usr/bin/env bash
# ------------------------------------------------------------------
# ram.sh – Waybar RAM utilisation module with rolling average
#
# Calculates 15-second rolling average (last 3 samples @ 5s interval)
# ------------------------------------------------------------------

set -euo pipefail

# History file for rolling average
HISTORY_FILE="/tmp/waybar_ram_history"

# Read memory info
mem_total=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
mem_available=$(awk '/MemAvailable/ {print $2}' /proc/meminfo)

# Calculate current usage percentage
mem_used=$((mem_total - mem_available))
current_usage=$(awk "BEGIN {printf \"%.0f\", ($mem_used / $mem_total) * 100}")

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

# Convert to GB for tooltip
mem_used_gb=$(awk "BEGIN {printf \"%.1f\", $mem_used / 1024 / 1024}")
mem_total_gb=$(awk "BEGIN {printf \"%.1f\", $mem_total / 1024 / 1024}")

# Get top 5 memory-consuming applications (aggregated by name)
# Disable pipefail temporarily to avoid SIGPIPE from head
set +o pipefail
top_processes=$(ps aux | awk -v total_gb="$mem_total_gb" 'NR>1 {
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

    # Aggregate memory by application name
    mem[cmd] += $4
}
END {
    # Sort by memory usage and output top 5
    for (app in mem) {
        # Calculate GB used: (percentage / 100) * total_gb
        gb_used = (mem[app] / 100) * total_gb
        printf "%s %.1f %.2f\n", app, mem[app], gb_used
    }
}' | sort -k2 -rn 2>/dev/null | head -n 5 | awk '{$1 = toupper(substr($1,1,1)) tolower(substr($1,2)); printf "▸ %s %.2fGB (%s%%)\\n", $1, $3, $2}')
set -o pipefail

# Build tooltip with top processes
tooltip="RAM: ${mem_used_gb}GB / ${mem_total_gb}GB (${avg_usage}%)\\n\\nTop 5 Memory Usage:\\n${top_processes}"

# Emit JSON for Waybar
echo "{\"text\":\"$avg_usage\",\"tooltip\":\"$tooltip\"}"
