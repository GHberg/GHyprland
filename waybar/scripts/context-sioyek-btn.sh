#!/bin/bash
# Fast button module - reads state from file
# Usage: context-sioyek-btn.sh [color_class]

COLOR_CLASS="${1:-yellow}"
STATE_FILE="/tmp/waybar-context-state"

ACTIVE_CLASS=$(cat "$STATE_FILE" 2>/dev/null)

if [[ "$ACTIVE_CLASS" == "sioyek" ]]; then
    printf '{"text": " ", "class": "%s", "tooltip": "Highlight %s"}\n' "$COLOR_CLASS" "$COLOR_CLASS"
else
    printf '{"text": "", "class": "hidden"}\n'
fi
