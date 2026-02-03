#!/usr/bin/env bash
# ------------------------------------------------------------------
# spotify-record-daemon.sh – Automatic music recording daemon
#
# Monitors playerctl metadata and automatically records each track
# to separate WAV files organized by Artist/Album
#
# Quality: 44.1 kHz, 32-bit float, bit-perfect digital capture
# ------------------------------------------------------------------

set -euo pipefail

# shellcheck source=music-player-detect.sh
. "$(dirname "$0")/music-player-detect.sh"

# Detect which player to record
PLAYER=$(get_active_player)
if [ -z "$PLAYER" ]; then
    echo "No supported music player running" >&2
    exit 1
fi

PLAYER_DISPLAY=$(get_player_display_name "$PLAYER")
PLAYER_APP=$(get_player_app_name "$PLAYER")

# Configuration
RECORDINGS_BASE="$HOME/Recordings/$PLAYER_DISPLAY"
PW_RECORD_PID_FILE="/tmp/waybar-spotify-record-pw-pid"
LAST_TRACK_ID_FILE="/tmp/waybar-spotify-last-trackid"
DAEMON_LOG="/tmp/waybar-spotify-record-daemon.log"

# Ensure recordings directory exists
mkdir -p "$RECORDINGS_BASE"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$DAEMON_LOG"
}

log "$PLAYER_DISPLAY recording daemon started (player: $PLAYER)"

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
    album_artist=$(playerctl -p "$PLAYER" metadata xesam:albumArtist 2>/dev/null || echo "")
    # Fallback to track artist if album artist not available
    if [ -z "$album_artist" ]; then
        album_artist=$(playerctl -p "$PLAYER" metadata xesam:artist 2>/dev/null || echo "Unknown Artist")
    fi

    artist=$(playerctl -p "$PLAYER" metadata xesam:artist 2>/dev/null || echo "Unknown Artist")
    title=$(playerctl -p "$PLAYER" metadata xesam:title 2>/dev/null || echo "Unknown")
    album=$(playerctl -p "$PLAYER" metadata xesam:album 2>/dev/null || echo "Singles")
    track_num=$(playerctl -p "$PLAYER" metadata xesam:trackNumber 2>/dev/null || echo "00")
    track_id=$(playerctl -p "$PLAYER" metadata mpris:trackid 2>/dev/null || echo "")
    position=$(playerctl -p "$PLAYER" position 2>/dev/null || echo "0")

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

    # Find the player's PipeWire node ID and sample rate
    local player_node
    player_node=$(get_player_pw_node "$PLAYER")
    local sample_rate
    sample_rate=$(get_player_sample_rate "$PLAYER")

    # If we found the player's node, record from it specifically
    if [ -n "$player_node" ]; then
        log "Found $PLAYER_DISPLAY node: $player_node (${sample_rate} Hz) - recording ONLY $PLAYER_DISPLAY audio"

        # Start pw-record targeting ONLY the player's audio stream (bit-perfect capture)
        pw-record \
            --target "$player_node" \
            --media-category Capture \
            --rate "$sample_rate" \
            --format f32 \
            --channels 2 \
            "$filepath" &
    else
        log "WARNING: Could not find $PLAYER_DISPLAY node, recording from default monitor (all audio)"

        # Fallback: record from monitor (captures all audio)
        pw-record \
            --media-category Capture \
            --rate "$sample_rate" \
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
log "Starting metadata monitor for $PLAYER_DISPLAY (playerctl -p $PLAYER)"

playerctl -p "$PLAYER" metadata --follow --format '{{mpris:trackid}}' 2>/dev/null | while read -r track_id; do
    # Check if player is playing
    status=$(playerctl -p "$PLAYER" status 2>/dev/null || echo "Stopped")

    if [ "$status" = "Playing" ]; then
        # Stop previous recording and start new one
        stop_recording
        start_recording
    else
        log "$PLAYER_DISPLAY not playing (status: $status), skipping recording"
    fi
done

# If playerctl exits, clean up
cleanup
