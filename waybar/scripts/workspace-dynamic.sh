#!/usr/bin/env bash
# ------------------------------------------------------------------
# workspace-dynamic.sh – Display dynamic workspaces (7+) for Waybar
#
# Shows workspaces 7 and above only when they have windows
# Clicking on a workspace number switches to it
# ------------------------------------------------------------------

set -euo pipefail

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
    "$HOME/.config/waybar/scripts/app-icons.sh" "$class"
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

# Get all workspace IDs >= 7 that have windows
dynamic_workspaces=$(echo "$workspaces" | jq -r '.[] | select(.id >= 7 and .windows > 0) | .id' | sort -n)

# If no dynamic workspaces, output empty
if [ -z "$dynamic_workspaces" ]; then
    echo "{\"text\":\"\",\"tooltip\":\"\",\"class\":\"dynamic-workspaces-empty\"}"
    exit 0
fi

# Build display for all dynamic workspaces
display_parts=()
tooltip_parts=()

while IFS= read -r ws_id; do
    [ -z "$ws_id" ] && continue

    # Get workspace info
    ws_info=$(echo "$workspaces" | jq -r --arg id "$ws_id" '.[] | select(.id == ($id | tonumber))')
    window_count=$(echo "$ws_info" | jq -r '.windows')

    if [ "$window_count" -gt 0 ]; then
        # Get all clients on this workspace
        workspace_windows=$(echo "$clients" | jq -c --arg id "$ws_id" \
            '.[] | select(.workspace.id == ($id | tonumber)) | {class: .class, title: .title}')

        # Build icon string and tooltip
        icon_string=""
        tooltip_apps=""

        while IFS= read -r window; do
            [ -z "$window" ] && continue

            class=$(echo "$window" | jq -r '.class')
            title=$(echo "$window" | jq -r '.title')

            icon=$(get_app_icon "$class")
            icon_string+="${icon} "

            # Get clean app name
            app_name=$(get_app_name "$class")
            app_name="$(echo "$app_name" | sed 's/^./\U&/')"  # Capitalize

            # Clean up title
            if [ -n "$title" ]; then
                title=$(echo "$title" | sed -e 's/ - Chromium$//' -e 's/ - Mozilla Firefox$//' \
                    -e 's/ - draw\.io$//' -e 's/\.drawio//' -e 's/ - Visual Studio Code$//' \
                    -e 's/ - VSCode$//' -e 's/ - Brave$//' -e 's/ - Google Chrome$//')
            fi

            # Build tooltip line
            if [ -n "$title" ]; then
                tooltip_apps+="$app_name: $title\\n"
            else
                tooltip_apps+="$app_name\\n"
            fi
        done <<< "$workspace_windows"

        # Trim trailing space and newline
        icon_string="${icon_string% }"
        tooltip_apps="${tooltip_apps%\\n}"

        # Build display: workspace number + icons
        workspace_display="$ws_id $icon_string"

        # Determine CSS class
        if [ "$ws_id" -eq "$active_workspace" ]; then
            css_class="active"
        else
            css_class="occupied"
        fi

        # Check if visible on any monitor
        if echo "$visible_workspaces" | grep -q "^${ws_id}$"; then
            css_class="${css_class} visible"
        fi

        # Add span with class and onclick handler
        display_parts+=("<span class='ws-${css_class}' onclick='hyprctl dispatch workspace ${ws_id}'>$workspace_display</span>")

        # Build tooltip
        tooltip_parts+=("Workspace $ws_id\\n$tooltip_apps")
    fi
done <<< "$dynamic_workspaces"

# Join all parts
if [ ${#display_parts[@]} -eq 0 ]; then
    echo "{\"text\":\"\",\"tooltip\":\"\",\"class\":\"dynamic-workspaces-empty\"}"
else
    display_text=$(IFS=' '; echo "${display_parts[*]}")
    tooltip_text=$(printf '%s\n\n' "${tooltip_parts[@]}")
    tooltip_text="${tooltip_text%\\n\\n}"  # Remove trailing newlines

    echo "{\"text\":\"$display_text\",\"tooltip\":\"$tooltip_text\",\"class\":\"dynamic-workspaces\"}"
fi
