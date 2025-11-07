#!/usr/bin/env bash
# ------------------------------------------------------------------
# gpu.sh – Waybar GPU utilisation module (Multi-vendor support)
#
# Supports AMD, Nvidia, and Intel GPUs with automatic detection
# 1️⃣ Detects GPU vendor and uses appropriate method
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
temp_primary="N/A"
temp_secondary="N/A"
temp_memory="N/A"
vram_used_gb="N/A"
vram_total_gb="N/A"
vram_percent="N/A"
gpu_vendor="Unknown"

# History file for rolling average (stores last 3 readings)
HISTORY_FILE="/tmp/waybar_gpu_history"

# ------------------------------------------------------------------
# GPU Detection and Vendor-Specific Collection
# ------------------------------------------------------------------

# Function to detect GPU vendor and collect metrics
detect_and_collect_gpu_metrics() {
    # Try Nvidia first (discrete GPU priority)
    if command -v nvidia-smi &>/dev/null; then
        if nvidia_data=$(nvidia-smi --query-gpu=utilization.gpu,temperature.gpu,memory.used,memory.total,power.draw --format=csv,noheader,nounits 2>/dev/null); then
            gpu_vendor="Nvidia"
            IFS=',' read -r current_usage temp_primary vram_used_mb vram_total_mb power <<< "$nvidia_data"

            # Clean up whitespace
            current_usage=$(echo "$current_usage" | xargs)
            temp_primary=$(echo "$temp_primary" | xargs)
            vram_used_mb=$(echo "$vram_used_mb" | xargs)
            vram_total_mb=$(echo "$vram_total_mb" | xargs)

            # Convert MB to GB for consistency
            vram_used_gb=$(awk "BEGIN {printf \"%.1f\", $vram_used_mb/1024}")
            vram_total_gb=$(awk "BEGIN {printf \"%.1f\", $vram_total_mb/1024}")
            vram_percent=$(awk "BEGIN {printf \"%.0f\", ($vram_used_mb/$vram_total_mb)*100}")

            return 0
        fi
    fi

    # Try AMD GPUs (check all cards)
    for card in /sys/class/drm/card[0-9]; do
        if [ ! -e "$card/device/gpu_busy_percent" ]; then
            continue
        fi

        gpu_vendor="AMD"
        GPU_BASE="$card/device"

        # Read current GPU usage
        if [ -e "$GPU_BASE/gpu_busy_percent" ]; then
            current_usage=$(<"$GPU_BASE/gpu_busy_percent")
        fi

        # Find hwmon directory
        HWMON=""
        if [ -d "$GPU_BASE/hwmon" ]; then
            HWMON=$(find "$GPU_BASE/hwmon" -maxdepth 1 -type d -name "hwmon*" | head -1)
        fi

        # Read temperatures
        if [ -n "$HWMON" ]; then
            if [ -e "$HWMON/temp1_input" ]; then
                temp_primary=$(($(cat "$HWMON/temp1_input") / 1000))
            fi
            if [ -e "$HWMON/temp2_input" ]; then
                temp_secondary=$(($(cat "$HWMON/temp2_input") / 1000))
            fi
            if [ -e "$HWMON/temp3_input" ]; then
                temp_memory=$(($(cat "$HWMON/temp3_input") / 1000))
            fi
        fi

        # Read VRAM usage
        if [ -e "$GPU_BASE/mem_info_vram_used" ] && [ -e "$GPU_BASE/mem_info_vram_total" ]; then
            vram_used_bytes=$(<"$GPU_BASE/mem_info_vram_used")
            vram_total_bytes=$(<"$GPU_BASE/mem_info_vram_total")
            vram_used_gb=$(awk "BEGIN {printf \"%.1f\", $vram_used_bytes/1024/1024/1024}")
            vram_total_gb=$(awk "BEGIN {printf \"%.1f\", $vram_total_bytes/1024/1024/1024}")
            vram_percent=$(awk "BEGIN {printf \"%.0f\", ($vram_used_bytes/$vram_total_bytes)*100}")
        fi

        return 0
    done

    # Try Intel GPUs
    for card in /sys/class/drm/card[0-9]; do
        if [ -e "$card/device/vendor" ]; then
            vendor_id=$(cat "$card/device/vendor")
            if [ "$vendor_id" = "0x8086" ]; then
                gpu_vendor="Intel"
                # Intel integrated GPUs have limited metrics available without intel_gpu_top
                # We can at least identify the GPU
                current_usage="N/A"
                return 0
            fi
        fi
    done

    return 1
}

# Collect GPU metrics
detect_and_collect_gpu_metrics

# Update history and calculate rolling average (only for numeric values)
if [ "$current_usage" != "N/A" ] && [ "$current_usage" -eq "$current_usage" ] 2>/dev/null; then
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
else
    usage="$current_usage"
fi

# Build tooltip based on vendor
case "$gpu_vendor" in
    Nvidia)
        tooltip="GPU: Nvidia\\nUsage: ${usage}%\\nTemperature: ${temp_primary}°C\\nVRAM: ${vram_used_gb}GB / ${vram_total_gb}GB (${vram_percent}%)"
        ;;
    AMD)
        tooltip="GPU: AMD\\nUsage: ${usage}%\\nTemperature (Edge): ${temp_primary}°C"
        if [ "$temp_secondary" != "N/A" ]; then
            tooltip="${tooltip}\\nTemperature (Junction): ${temp_secondary}°C"
        fi
        if [ "$temp_memory" != "N/A" ]; then
            tooltip="${tooltip}\\nTemperature (Memory): ${temp_memory}°C"
        fi
        tooltip="${tooltip}\\nVRAM: ${vram_used_gb}GB / ${vram_total_gb}GB (${vram_percent}%)"
        ;;
    Intel)
        tooltip="GPU: Intel (integrated)\\nLimited metrics available\\nInstall intel_gpu_top for detailed monitoring"
        ;;
    *)
        tooltip="No supported GPU detected"
        ;;
esac

# Emit JSON for Waybar
echo "{\"text\":\"$usage\",\"tooltip\":\"$tooltip\"}"
