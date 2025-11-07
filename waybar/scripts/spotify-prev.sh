#!/usr/bin/env bash
# ------------------------------------------------------------------
# spotify-prev.sh – Previous track button
# ------------------------------------------------------------------

set -euo pipefail

# Handle click
if [ "${1:-}" = "prev" ]; then
    playerctl -p spotify previous 2>/dev/null
    exit 0
fi

# Check if Spotify is running
if ! playerctl -p spotify status &>/dev/null; then
    echo "{\"text\":\"\",\"tooltip\":\"\",\"class\":\"hidden\"}"
    exit 0
fi

# Always show button when Spotify is active
echo "{\"text\":\"⏮\",\"tooltip\":\"Previous track\",\"class\":\"control\"}"
