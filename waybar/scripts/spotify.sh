#!/usr/bin/env bash
# ------------------------------------------------------------------
# spotify.sh – Music player control and display for Waybar
#
# Shows: Song by Artist | Time
# ------------------------------------------------------------------

set -euo pipefail

# shellcheck source=music-player-detect.sh
. "$(dirname "$0")/music-player-detect.sh"

STATE_FILE="/tmp/waybar-spotify-state"
RECORDING_ENABLED_FILE="/tmp/waybar-spotify-recording-enabled"

# Check if any supported player is running
PLAYER=$(get_active_player)
if [ -z "$PLAYER" ]; then
    echo "{\"text\":\"\",\"tooltip\":\"\",\"class\":\"hidden\"}"
    exit 0
fi

# Check if collapsed
if [ -f "$STATE_FILE" ]; then
    state=$(cat "$STATE_FILE")
    if [ "$state" = "collapsed" ]; then
        echo "{\"text\":\"\",\"tooltip\":\"\",\"class\":\"hidden\"}"
        exit 0
    fi
fi

# Get playback info
status=$(playerctl -p "$PLAYER" status 2>/dev/null || echo "Stopped")
title=$(playerctl -p "$PLAYER" metadata title 2>/dev/null || echo "No Title")
artist=$(playerctl -p "$PLAYER" metadata artist 2>/dev/null || echo "Unknown Artist")
position=$(playerctl -p "$PLAYER" position 2>/dev/null || echo "0")
duration=$(playerctl -p "$PLAYER" metadata mpris:length 2>/dev/null || echo "0")

# Convert position to seconds (playerctl returns float)
position_sec=$(printf "%.0f" "$position")

# Convert duration from microseconds to seconds
duration_sec=$((duration / 1000000))

# Format time as MM:SS
format_time() {
    local total_seconds=$1
    local minutes=$((total_seconds / 60))
    local seconds=$((total_seconds % 60))
    printf "%d:%02d" $minutes $seconds
}

position_str=$(format_time $position_sec)
duration_str=$(format_time $duration_sec)

# Truncate song title if too long
if [ ${#title} -gt 30 ]; then
    title="${title:0:27}..."
fi

if [ ${#artist} -gt 20 ]; then
    artist="${artist:0:17}..."
fi

# Build display text
# Format: "Title by Artist  MM:SS/MM:SS" (title in italic)
display_text="<i>$title</i> by $artist  $position_str/$duration_str"

# Build tooltip
player_name=$(get_player_display_name "$PLAYER")
tooltip="🎵 $player_name\\n\\n"
tooltip+="Title: $title\\n"
tooltip+="Artist: $artist\\n"
tooltip+="Status: $status\\n"
tooltip+="Time: $position_str / $duration_str"

# Add recording status if enabled
if [ -f "$RECORDING_ENABLED_FILE" ] && [ "$(cat "$RECORDING_ENABLED_FILE")" = "1" ]; then
    local rec_rate
    rec_rate=$(get_player_sample_rate "$PLAYER")
    tooltip+="\\n\\n⏺ Recording: ENABLED\\n"
    tooltip+="Quality: ${rec_rate} Hz, 32-bit float"
fi

# Determine CSS class based on status
case "$status" in
    Playing)
        css_class="playing"
        ;;
    Paused)
        css_class="paused"
        ;;
    *)
        css_class="stopped"
        ;;
esac

# Output JSON
echo "{\"text\":\"$display_text\",\"tooltip\":\"$tooltip\",\"class\":\"$css_class\"}"
