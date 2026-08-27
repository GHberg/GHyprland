#!/bin/bash
# Single module that outputs all Sioyek buttons at once

ACTIVE_CLASS=$(hyprctl activewindow -j 2>/dev/null | jq -r '.class // empty' 2>/dev/null | tr '[:upper:]' '[:lower:]')

if [[ "$ACTIVE_CLASS" == "sioyek" ]]; then
    echo '{"text": "󰛿  󰛿  󰛿  󰛿", "class": "visible", "tooltip": "Sioyek Highlights"}'
else
    echo '{"text": "", "class": "hidden"}'
fi
