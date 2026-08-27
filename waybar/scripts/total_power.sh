#!/usr/bin/env bash
# ------------------------------------------------------------------
# total_power.sh – Waybar total system power consumption module
#
# Calculates CPU + GPU power consumption with 3-second rolling average
# CPU: Uses RAPL (Running Average Power Limit) energy counters
# GPU: Uses hwmon power sensors (AMD/Nvidia)
# Rolling average: Last 3 samples @ 1s interval = 3-second average
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

# ------------------------------------------------------------------
# CPU Power (RAPL)
# ------------------------------------------------------------------

get_cpu_power() {
    local total_power_w=0
    local cache_file="/tmp/waybar_cpu_power_cache"

    # Read RAPL energy counters
    if [ -d /sys/class/powercap/intel-rapl ]; then
        local current_energy=0
        local current_time=$(date +%s%N)  # nanoseconds

        shopt -s nullglob
        # Sum energy from all RAPL domains (package + cores)
        for energy_file in /sys/class/powercap/intel-rapl/intel-rapl:*/energy_uj; do
            if [ -f "$energy_file" ]; then
                local energy_uj=$(cat "$energy_file" 2>/dev/null || echo 0)
                current_energy=$((current_energy + energy_uj))
            fi
        done
        shopt -u nullglob

        # Calculate power if we have a previous reading
        if [ -f "$cache_file" ]; then
            read prev_energy prev_time < "$cache_file"

            # Calculate time delta (nanoseconds to seconds)
            local time_delta=$(awk "BEGIN {printf \"%.6f\", ($current_time - $prev_time) / 1000000000}")

            # Calculate energy delta (microjoules to joules)
            local energy_delta=$(awk "BEGIN {printf \"%.6f\", ($current_energy - $prev_energy) / 1000000}")

            # Power = Energy / Time (watts)
            if (( $(awk "BEGIN {print ($time_delta > 0)}") )); then
                total_power_w=$(awk "BEGIN {printf \"%.0f\", $energy_delta / $time_delta}")
            fi
        fi

        # Save current reading for next run
        echo "$current_energy $current_time" > "$cache_file"
    fi

    echo "$total_power_w"
}

# ------------------------------------------------------------------
# GPU Power
# ------------------------------------------------------------------

get_gpu_power() {
    local gpu_power_w=0

    # Try Nvidia first - check for actual hardware before running nvidia-smi
    if lspci 2>/dev/null | grep -qi 'VGA.*NVIDIA\|3D.*NVIDIA\|Display.*NVIDIA'; then
        if command -v nvidia-smi &>/dev/null; then
            if gpu_power=$(nvidia-smi --query-gpu=power.draw --format=csv,noheader,nounits 2>/dev/null | head -1); then
                # nvidia-smi returns watts directly
                gpu_power_w=$(printf "%.0f" "$gpu_power" 2>/dev/null || echo 0)
                echo "$gpu_power_w"
                return 0
            fi
        fi
    fi

    # Try AMD GPUs - find the dedicated GPU by VRAM size
    local best_card=""
    local best_vram=0

    for card in /sys/class/drm/card[0-9]; do
        if [ ! -e "$card/device" ]; then
            continue
        fi

        # Check VRAM size to find dedicated GPU
        if [ -e "$card/device/mem_info_vram_total" ]; then
            vram_total=$(<"$card/device/mem_info_vram_total")
            if [ "$vram_total" -gt "$best_vram" ]; then
                best_vram=$vram_total
                best_card=$card
            fi
        fi
    done

    # Read power from best card
    if [ -n "$best_card" ]; then
        local hwmon=$(find "$best_card/device/hwmon" -mindepth 1 -maxdepth 1 -type d -name "hwmon*" 2>/dev/null | head -1)

        if [ -n "$hwmon" ]; then
            # Try different power sensor files
            for power_file in "$hwmon/power1_average" "$hwmon/power1_input"; do
                if [ -f "$power_file" ]; then
                    local power_uw=$(cat "$power_file" 2>/dev/null || echo 0)
                    # Convert microwatts to watts
                    gpu_power_w=$((power_uw / 1000000))
                    break
                fi
            done
        fi
    fi

    echo "$gpu_power_w"
}

# ------------------------------------------------------------------
# Main
# ------------------------------------------------------------------

# Get power readings
cpu_power=$(get_cpu_power)
gpu_power=$(get_gpu_power)

# Calculate current total
current_total=$((cpu_power + gpu_power))

# ------------------------------------------------------------------
# Rolling Average (3-second window: last 3 samples)
# ------------------------------------------------------------------

HISTORY_FILE="/tmp/waybar_power_history"

# Update history and calculate rolling average
if [ -f "$HISTORY_FILE" ]; then
    mapfile -t history < "$HISTORY_FILE"
else
    history=()
fi

# Add current reading
history+=("$current_total")

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
total_power=$((sum / ${#history[@]}))

# Build tooltip
tooltip="System Power:\\nCPU: ${cpu_power}W\\nGPU: ${gpu_power}W\\nTotal: ${total_power}W (3s avg)"

# Emit JSON for Waybar
echo "{\"text\":\"${total_power}\",\"tooltip\":\"$tooltip\"}"
