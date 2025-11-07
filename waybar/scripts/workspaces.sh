#!/usr/bin/env bash
# ------------------------------------------------------------------
# workspaces.sh – Custom Hyprland workspace display for Waybar
#
# Shows workspace numbers, but displays app name if only one app running
# ------------------------------------------------------------------

set -euo pipefail

# Get workspace and client information
workspaces=$(hyprctl workspaces -j)
clients=$(hyprctl clients -j)
active_workspace=$(hyprctl activeworkspace -j | jq -r '.id')

# Function to extract clean application name from class (first 3 letters only)
get_app_name() {
    local class="$1"
    local app_name="$class"

    # Handle chrome apps (chrome-chatgpt.com__-Default -> Chatgpt)
    if [[ "$class" =~ ^chrome-([^.]+) ]]; then
        app_name="${BASH_REMATCH[1]}"
    # Handle other common patterns
    elif [[ "$class" =~ ^org\.kde\.([^.]+) ]]; then
        app_name="${BASH_REMATCH[1]}"
    fi

    # Capitalize first letter and take only first 3 characters
    app_name="$(tr '[:lower:]' '[:upper:]' <<< ${app_name:0:1})${app_name:1}"
    app_name="${app_name:0:3}"

    echo "$app_name"
}

# Build workspace display
workspace_output=""
for ws_id in $(seq 1 6); do
    # Check if workspace exists and get window count
    ws_info=$(echo "$workspaces" | jq -r --arg id "$ws_id" '.[] | select(.id == ($id | tonumber))')

    if [ -n "$ws_info" ]; then
        window_count=$(echo "$ws_info" | jq -r '.windows')

        # Determine display text
        if [ "$window_count" -eq 1 ]; then
            # Get the single client on this workspace
            client_class=$(echo "$clients" | jq -r --arg id "$ws_id" '.[] | select(.workspace.id == ($id | tonumber)) | .class' | head -n1)
            if [ -n "$client_class" ]; then
                display_text=$(get_app_name "$client_class")
            else
                display_text="$ws_id"
            fi
        else
            display_text="$ws_id"
        fi

        # Use bold for active workspace, alpha for empty
        if [ "$ws_id" -eq "$active_workspace" ]; then
            workspace_output+="<b>$display_text</b> "
        else
            workspace_output+="$display_text "
        fi
    else
        # Empty workspace - still show the number if it's persistent
        if [ "$ws_id" -le 6 ]; then
            workspace_output+="<span alpha='50%'>$ws_id</span> "
        fi
    fi
done

# Output as JSON for Waybar
echo "{\"text\":\"$workspace_output\",\"tooltip\":\"Workspaces\",\"class\":\"workspaces\"}"
