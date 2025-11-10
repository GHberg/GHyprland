#!/usr/bin/env bash
# ------------------------------------------------------------------
# workspace-add.sh – Add new workspace button for Waybar
#
# Usage: workspace-add.sh [click]
# Displays: + icon
# On click: Creates and switches to next sequential workspace
# ------------------------------------------------------------------

set -euo pipefail

ACTION="${1:-}"

# Handle click action
if [ "$ACTION" = "click" ]; then
    # Get all workspace IDs
    workspaces=$(hyprctl workspaces -j)

    # Find the highest workspace ID
    highest_ws=$(echo "$workspaces" | jq -r 'map(.id) | max // 6')

    # Switch to next workspace (this will create it if it doesn't exist)
    next_ws=$((highest_ws + 1))
    hyprctl dispatch workspace "$next_ws"

    exit 0
fi

# Default display: just show the + icon
display_text="+"
tooltip_text="Add new workspace"
css_class="add-workspace"

# Output as JSON for Waybar
echo "{\"text\":\"$display_text\",\"tooltip\":\"$tooltip_text\",\"class\":\"$css_class\"}"
