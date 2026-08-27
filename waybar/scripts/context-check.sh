#!/bin/bash
# Writes current context to a temp file for other modules to read

STATE_FILE="/tmp/waybar-context-state"
ACTIVE_CLASS=$(hyprctl activewindow -j 2>/dev/null | jq -r '.class // empty' 2>/dev/null | tr '[:upper:]' '[:lower:]')

echo "$ACTIVE_CLASS" > "$STATE_FILE"
