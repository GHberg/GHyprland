#!/usr/bin/env bash
# ------------------------------------------------------------------
# spotify.sh – Spotify control and display for Waybar
#
# Shows: Icon | Song - Artist | Time | Controls
# ------------------------------------------------------------------

set -euo pipefail

# Check if Spotify is running
if ! playerctl -p spotify status &>/dev/null; then
    echo "{\"text\":\"\",\"tooltip\":\"\",\"class\":\"hidden\"}"
    exit 0
fi

# Get playback info
status=$(playerctl -p spotify status 2>/dev/null || echo "Stopped")
title=$(playerctl -p spotify metadata title 2>/dev/null || echo "No Title")
artist=$(playerctl -p spotify metadata artist 2>/dev/null || echo "Unknown Artist")
position=$(playerctl -p spotify position 2>/dev/null || echo "0")
duration=$(playerctl -p spotify metadata mpris:length 2>/dev/null || echo "0")

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
# Using Nerd Font Spotify icon, then title, then artist, then time
spotify_icon=$'\uf1bc'  # nf-fa-spotify
display_text="$spotify_icon $title  $artist  $position_str/$duration_str"

# Build tooltip
tooltip="🎵 Spotify\\n\\n"
tooltip+="Title: $title\\n"
tooltip+="Artist: $artist\\n"
tooltip+="Status: $status\\n"
tooltip+="Time: $position_str / $duration_str"

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
