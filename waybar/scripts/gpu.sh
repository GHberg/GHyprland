#!/usr/bin/env bash
# ------------------------------------------------------------------
# gpu.sh – Waybar GPU utilisation module (AMD dedicated GPU)
#
# 1️⃣ Reads GPU usage, temperature, and VRAM from sysfs
# 2️⃣ Calculates 15-second rolling average (last 3 samples)
# 3️⃣ Outputs JSON with tooltip showing detailed info
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

# Defaults
usage="N/A"
temp_edge="N/A"
temp_junction="N/A"
temp_mem="N/A"
vram_used_gb="N/A"
vram_total_gb="N/A"
vram_percent="N/A"

# GPU card to monitor
CARD="card1"
GPU_BASE="/sys/class/drm/$CARD/device"

# History file for rolling average (stores last 3 readings)
HISTORY_FILE="/tmp/waybar_gpu_history"

# Read current GPU usage percentage
current_usage="N/A"
if [ -e "$GPU_BASE/gpu_busy_percent" ]; then
    current_usage=$(<"$GPU_BASE/gpu_busy_percent")
fi

# Update history and calculate rolling average
if [ "$current_usage" != "N/A" ]; then
    # Read existing history or create new
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
        sum=$((sum + val))
    done
    usage=$((sum / ${#history[@]}))
fi

# Read temperatures (convert from millidegrees to degrees)
HWMON="$GPU_BASE/hwmon/hwmon2"
if [ -e "$HWMON/temp1_input" ]; then
    temp_edge=$(($(cat "$HWMON/temp1_input") / 1000))
fi
if [ -e "$HWMON/temp2_input" ]; then
    temp_junction=$(($(cat "$HWMON/temp2_input") / 1000))
fi
if [ -e "$HWMON/temp3_input" ]; then
    temp_mem=$(($(cat "$HWMON/temp3_input") / 1000))
fi

# Read VRAM usage (convert bytes to GB)
if [ -e "$GPU_BASE/mem_info_vram_used" ] && [ -e "$GPU_BASE/mem_info_vram_total" ]; then
    vram_used_bytes=$(<"$GPU_BASE/mem_info_vram_used")
    vram_total_bytes=$(<"$GPU_BASE/mem_info_vram_total")
    vram_used_gb=$(awk "BEGIN {printf \"%.1f\", $vram_used_bytes/1024/1024/1024}")
    vram_total_gb=$(awk "BEGIN {printf \"%.1f\", $vram_total_bytes/1024/1024/1024}")
    vram_percent=$(awk "BEGIN {printf \"%.0f\", ($vram_used_bytes/$vram_total_bytes)*100}")
fi

# Build tooltip with detailed information (using \n for newlines in JSON)
tooltip="GPU Usage: ${usage}%\\nTemperature (Edge): ${temp_edge}°C\\nTemperature (Junction): ${temp_junction}°C\\nTemperature (Memory): ${temp_mem}°C\\nVRAM: ${vram_used_gb}GB / ${vram_total_gb}GB (${vram_percent}%)"

# Emit JSON for Waybar
echo "{\"text\":\"$usage\",\"tooltip\":\"$tooltip\"}"
