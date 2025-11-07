#!/usr/bin/env bash
# ------------------------------------------------------------------
# workspace-single.sh – Display a single workspace for Waybar
#
# Usage: workspace-single.sh <workspace_id>
# Displays: <number> [<icons>] with multipliers for duplicates
# ------------------------------------------------------------------

set -euo pipefail

WORKSPACE_ID="${1:-1}"

# Get workspace, client, and monitor information
workspaces=$(hyprctl workspaces -j)
clients=$(hyprctl clients -j)
monitors=$(hyprctl monitors -j)
active_workspace=$(hyprctl activeworkspace -j | jq -r '.id')

# Get list of workspaces currently visible on any monitor
visible_workspaces=$(echo "$monitors" | jq -r '.[].activeWorkspace.id')

# Function to map application class to Nerd Font icon
get_app_icon() {
    local class="$1"
    # Use external helper script for icon mapping
    /home/bjorn/.config/waybar/scripts/app-icons.sh "$class"
}

# Function to extract clean application name from class
get_app_name() {
    local class="$1"
    local app_name="$class"

    # Handle chrome apps (chrome-chatgpt.com__-Default -> chatgpt)
    if [[ "$class" =~ ^chrome-([^.]+) ]]; then
        app_name="${BASH_REMATCH[1]}"
    # Handle other common patterns
    elif [[ "$class" =~ ^org\.kde\.([^.]+) ]]; then
        app_name="${BASH_REMATCH[1]}"
    fi

    echo "$app_name"
}

# Check if workspace exists and get window count
ws_info=$(echo "$workspaces" | jq -r --arg id "$WORKSPACE_ID" '.[] | select(.id == ($id | tonumber))')

if [ -n "$ws_info" ]; then
    window_count=$(echo "$ws_info" | jq -r '.windows')

    if [ "$window_count" -gt 0 ]; then
        # Get all clients on this workspace
        workspace_clients=$(echo "$clients" | jq -r --arg id "$WORKSPACE_ID" '.[] | select(.workspace.id == ($id | tonumber)) | .class')

        # Build icon string by showing each app icon individually
        icon_string=""
        while IFS= read -r class; do
            [ -z "$class" ] && continue
            icon=$(get_app_icon "$class")
            icon_string+="${icon} "
        done <<< "$workspace_clients"

        # Trim trailing space
        icon_string="${icon_string% }"

        # Display format: <number> <icons> (no brackets, icons repeat for each instance)
        display_text="$WORKSPACE_ID $icon_string"
    else
        # No windows
        display_text="$WORKSPACE_ID"
    fi

    # Check if this is the active workspace
    if [ "$WORKSPACE_ID" -eq "$active_workspace" ]; then
        # If active but no apps, use special class for circle
        if [ "$window_count" -eq 0 ]; then
            css_class="active-empty"
        else
            css_class="active"
        fi
    else
        css_class="occupied"
    fi
else
    # Empty workspace
    display_text="$WORKSPACE_ID"
    css_class="empty"
fi

# Check if workspace is visible on any monitor and add 'visible' class
if echo "$visible_workspaces" | grep -q "^${WORKSPACE_ID}$"; then
    css_class="${css_class} visible"
fi

# Output as JSON for Waybar
echo "{\"text\":\"$display_text\",\"tooltip\":\"Workspace $WORKSPACE_ID\",\"class\":\"$css_class\"}"
