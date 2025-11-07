#!/usr/bin/env bash
# ------------------------------------------------------------------
# spotify-next.sh – Next track button
# ------------------------------------------------------------------

set -euo pipefail

# Handle click
if [ "${1:-}" = "next" ]; then
    playerctl -p spotify next 2>/dev/null
    exit 0
fi

# Check if Spotify is running
if ! playerctl -p spotify status &>/dev/null; then
    echo "{\"text\":\"\",\"tooltip\":\"\",\"class\":\"hidden\"}"
    exit 0
fi

# Always show button when Spotify is active
echo "{\"text\":\"⏭\",\"tooltip\":\"Next track\",\"class\":\"control\"}"
