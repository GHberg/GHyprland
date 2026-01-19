#!/usr/bin/env bash
# ------------------------------------------------------------------
# spotify-record-daemon.sh – Automatic Spotify recording daemon
#
# Monitors playerctl metadata and automatically records each track
# to separate WAV files organized by Artist/Album
#
# Quality: 44.1 kHz, 32-bit float, bit-perfect digital capture
# ------------------------------------------------------------------

set -euo pipefail

# Configuration
RECORDINGS_BASE="$HOME/Recordings/Spotify"
PW_RECORD_PID_FILE="/tmp/waybar-spotify-record-pw-pid"
LAST_TRACK_ID_FILE="/tmp/waybar-spotify-last-trackid"
DAEMON_LOG="/tmp/waybar-spotify-record-daemon.log"

# Ensure recordings directory exists
mkdir -p "$RECORDINGS_BASE"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$DAEMON_LOG"
}

log "Spotify recording daemon started"

# Function to sanitize filenames
sanitize_filename() {
    local name="$1"
    # Replace invalid characters with underscore
    name="${name//[\/\\:*?\"<>|]/_}"
    # Remove leading/trailing spaces and dots
    name="${name#"${name%%[![:space:].]*}"}"
    name="${name%"${name##*[![:space:].]}"}"
    # Truncate to 200 chars
    if [ ${#name} -gt 200 ]; then
        name="${name:0:200}"
    fi
    echo "$name"
}

# Function to stop current recording
stop_recording() {
    if [ -f "$PW_RECORD_PID_FILE" ]; then
        local pid
        pid=$(cat "$PW_RECORD_PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            log "Stopping pw-record (PID: $pid)"
            kill "$pid" 2>/dev/null || true
            wait "$pid" 2>/dev/null || true
        fi
        rm -f "$PW_RECORD_PID_FILE"
    fi
}

# Function to start recording for current track
start_recording() {
    # Get metadata
    local artist album_artist title album track_num track_id position

    # Use albumArtist for folder organization (consistent across all tracks in album)
    album_artist=$(playerctl -p spotify metadata xesam:albumArtist 2>/dev/null || echo "")
    # Fallback to track artist if album artist not available
    if [ -z "$album_artist" ]; then
        album_artist=$(playerctl -p spotify metadata xesam:artist 2>/dev/null || echo "Unknown Artist")
    fi

    artist=$(playerctl -p spotify metadata xesam:artist 2>/dev/null || echo "Unknown Artist")
    title=$(playerctl -p spotify metadata xesam:title 2>/dev/null || echo "Unknown")
    album=$(playerctl -p spotify metadata xesam:album 2>/dev/null || echo "Singles")
    track_num=$(playerctl -p spotify metadata xesam:trackNumber 2>/dev/null || echo "00")
    track_id=$(playerctl -p spotify metadata mpris:trackid 2>/dev/null || echo "")
    position=$(playerctl -p spotify position 2>/dev/null || echo "0")

    # Check track position - only record if at the beginning (within first 3 seconds)
    position_int=$(printf "%.0f" "$position" 2>/dev/null || echo "999")
    if [ "$position_int" -gt 3 ]; then
        log "Track already playing at ${position_int}s, skipping to ensure full recording"
        # Mark this track as seen so we don't try to record it again
        echo "$track_id" > "$LAST_TRACK_ID_FILE"
        return
    fi

    # Check if this is the same track as last time (avoid duplicate on metadata refresh)
    if [ -f "$LAST_TRACK_ID_FILE" ]; then
        local last_track_id
        last_track_id=$(cat "$LAST_TRACK_ID_FILE")
        if [ "$track_id" = "$last_track_id" ]; then
            log "Same track ID detected, skipping duplicate recording"
            return
        fi
    fi

    # Save current track ID
    echo "$track_id" > "$LAST_TRACK_ID_FILE"

    # Sanitize names
    album_artist=$(sanitize_filename "$album_artist")
    album=$(sanitize_filename "$album")
    title=$(sanitize_filename "$title")

    # Format track number (pad to 2 digits)
    track_num=$(printf "%02d" "$track_num" 2>/dev/null || echo "00")

    # Build file path using album artist (keeps all tracks from same album together)
    local target_dir="$RECORDINGS_BASE/$album_artist/$album"
    local base_filename="${track_num} - ${title}.wav"
    local filepath="$target_dir/$base_filename"

    # Handle duplicate filenames
    local counter=2
    while [ -f "$filepath" ]; do
        base_filename="${track_num} - ${title} (${counter}).wav"
        filepath="$target_dir/$base_filename"
        ((counter++))
    done

    # Create directory
    mkdir -p "$target_dir"

    log "Starting recording: $filepath"

    # Find Spotify's PipeWire node name dynamically
    # First try: pw-cli (more accurate)
    local spotify_node
    spotify_node=$(pw-cli list-objects | grep -A 3 "application.name = \"spotify\"" | grep "node.name" | head -1 | awk -F'"' '{print $2}')

    # Second try: pactl (alternative method)
    if [ -z "$spotify_node" ]; then
        spotify_node=$(pactl list sink-inputs | grep -B 20 "application.name = \"spotify\"" | grep "Sink Input" | head -1 | awk '{print $3}' | tr -d '#')
    fi

    # If we found Spotify's node, record from it specifically
    if [ -n "$spotify_node" ]; then
        log "Found Spotify node: $spotify_node - recording ONLY Spotify audio"

        # Start pw-record targeting ONLY Spotify's audio stream (bit-perfect capture at 44.1 kHz, 32-bit float)
        pw-record \
            --target "$spotify_node" \
            --media-category Capture \
            --rate 44100 \
            --format f32 \
            --channels 2 \
            "$filepath" &
    else
        log "WARNING: Could not find Spotify node, recording from default monitor (all audio)"

        # Fallback: record from monitor (captures all audio)
        pw-record \
            --media-category Capture \
            --rate 44100 \
            --format f32 \
            --channels 2 \
            "$filepath" &
    fi

    local pw_pid=$!
    echo "$pw_pid" > "$PW_RECORD_PID_FILE"

    log "Recording started (PID: $pw_pid)"
}

# Cleanup function
cleanup() {
    log "Daemon shutting down"
    stop_recording
    rm -f "$LAST_TRACK_ID_FILE"
    exit 0
}

trap cleanup SIGTERM SIGINT

# Main monitoring loop
log "Starting metadata monitor"

playerctl -p spotify metadata --follow --format '{{mpris:trackid}}' 2>/dev/null | while read -r track_id; do
    # Check if Spotify is playing
    status=$(playerctl -p spotify status 2>/dev/null || echo "Stopped")

    if [ "$status" = "Playing" ]; then
        # Stop previous recording and start new one
        stop_recording
        start_recording
    else
        log "Spotify not playing (status: $status), skipping recording"
    fi
done

# If playerctl exits, clean up
cleanup
