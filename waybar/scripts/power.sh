#!/usr/bin/env bash
# ------------------------------------------------------------------
# power.sh – Waybar GPU electricity cost module
#
# Calculates GPU electricity cost per hour with 60-second rolling average
# Updates every 20 seconds
# ------------------------------------------------------------------

set -euo pipefail

# History file for rolling average (stores last 3 readings @ 20s interval = 60s)
HISTORY_FILE="/tmp/waybar_gpu_cost_history"

# Electricity cost per kWh in euros
COST_PER_KWH=0.35

# Read GPU power (in microwatts, convert to watts)
gpu_power_w=0
if [ -f "/sys/class/drm/card1/device/hwmon/hwmon2/power1_average" ]; then
    gpu_power_uw=$(cat /sys/class/drm/card1/device/hwmon/hwmon2/power1_average 2>/dev/null || echo 0)
    gpu_power_w=$(awk "BEGIN {printf \"%.1f\", $gpu_power_uw / 1000000}")
fi

# Update history and calculate rolling average
if [ -f "$HISTORY_FILE" ]; then
    mapfile -t history < "$HISTORY_FILE"
else
    history=()
fi

# Add current reading
history+=("$gpu_power_w")

# Keep only last 3 readings (60 seconds @ 20s interval)
if [ ${#history[@]} -gt 3 ]; then
    history=("${history[@]: -3}")
fi

# Save updated history
printf "%s\n" "${history[@]}" > "$HISTORY_FILE"

# Calculate average power in watts
sum=0
for val in "${history[@]}"; do
    sum=$(awk "BEGIN {printf \"%.6f\", $sum + $val}")
done
avg_power_w=$(awk "BEGIN {printf \"%.1f\", $sum / ${#history[@]}}")

# Convert to kW
avg_power_kw=$(awk "BEGIN {printf \"%.6f\", $avg_power_w / 1000}")

# Calculate cost per hour: kW * €/kWh
cost_per_hour=$(awk "BEGIN {printf \"%.3f\", $avg_power_kw * $COST_PER_KWH}")

# Build tooltip showing calculation breakdown
tooltip="GPU Power: ${avg_power_w}W\\nCost per hour: €${cost_per_hour}\\nCost per day: €$(awk "BEGIN {printf \"%.2f\", $cost_per_hour * 24}")\\nElectricity rate: €${COST_PER_KWH}/kWh"

# Emit JSON for Waybar
echo "{\"text\":\"$cost_per_hour\",\"tooltip\":\"$tooltip\"}"
