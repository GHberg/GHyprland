#!/usr/bin/env bash
# ------------------------------------------------------------------
# music-player-detect.sh – Shared helper for multi-player detection
#
# Sourced by all spotify-*.sh scripts. Provides functions to detect
# which music player (Spotify or Tidal) is active.
#
# Priority: prefer the player currently "Playing". If neither is
# playing, prefer whichever is at least running.
# ------------------------------------------------------------------

# List of supported players in preference order
_SUPPORTED_PLAYERS=("tidal-hifi" "spotify")

# Resolve tidal-hifi when it registers as a chromium.instance* player.
# tidal-hifi is an Electron app whose MPRIS name is chromium.instance<PID>,
# where <PID> matches the main tidal-hifi process.
_resolve_tidal_chromium() {
    local tidal_pid
    tidal_pid=$(pgrep -x tidal-hifi 2>/dev/null | head -1) || return
    [ -z "$tidal_pid" ] && return

    local p
    for p in $(playerctl -l 2>/dev/null); do
        if [ "$p" = "chromium.instance${tidal_pid}" ]; then
            echo "$p"
            return
        fi
    done
}

# Return the playerctl player name that should be controlled right now.
# Prints "spotify", "chromium.instance<PID>" (for Tidal), or "" (empty = nothing running).
get_active_player() {
    local playing=""
    local running=""

    for p in "${_SUPPORTED_PLAYERS[@]}"; do
        local actual_name="$p"

        # tidal-hifi registers under chromium.instance<PID>; resolve it
        if [ "$p" = "tidal-hifi" ]; then
            actual_name=$(_resolve_tidal_chromium) || continue
            [ -z "$actual_name" ] && continue
        fi

        local status
        status=$(playerctl -p "$actual_name" status 2>/dev/null) || continue

        if [ "$status" = "Playing" ] && [ -z "$playing" ]; then
            playing="$actual_name"
        fi
        if [ -z "$running" ]; then
            running="$actual_name"
        fi
    done

    # Prefer the one that is Playing; fall back to one that is at least running
    if [ -n "$playing" ]; then
        echo "$playing"
    else
        echo "$running"
    fi
}

# Check if a player name corresponds to tidal-hifi (either native or chromium.instance*)
_is_tidal() {
    local player="$1"
    [ "$player" = "tidal-hifi" ] && return 0
    case "$player" in
        chromium.instance*)
            local pid="${player#chromium.instance}"
            local tidal_pid
            tidal_pid=$(pgrep -x tidal-hifi 2>/dev/null | head -1) || return 1
            [ "$pid" = "$tidal_pid" ] && return 0
            ;;
    esac
    return 1
}

# Return an icon character for the given player (or the active one).
get_player_icon() {
    local player="${1:-$(get_active_player)}"
    if [ "$player" = "spotify" ]; then
        printf '\uf1bc'   # nf-fa-spotify
    elif _is_tidal "$player"; then
        printf '\uf001'   # nf-fa-music (generic music note for Tidal)
    else
        printf '\uf001'
    fi
}

# Return a human-readable name for the given player (or the active one).
get_player_display_name() {
    local player="${1:-$(get_active_player)}"
    if [ "$player" = "spotify" ]; then
        echo "Spotify"
    elif _is_tidal "$player"; then
        echo "Tidal"
    else
        echo "Music"
    fi
}

# Return the PipeWire / PulseAudio application.name used to find the
# player's audio node (for targeted recording).
get_player_app_name() {
    local player="${1:-$(get_active_player)}"
    if [ "$player" = "spotify" ]; then
        echo "spotify"
    elif _is_tidal "$player"; then
        echo "tidal-hifi"
    else
        echo ""
    fi
}

# Return the PipeWire node ID for the player's audio output stream.
# tidal-hifi registers as "Chromium" in PipeWire, so we match by
# application.process.binary instead of application.name.
get_player_pw_node() {
    local player="${1:-$(get_active_player)}"
    if _is_tidal "$player"; then
        pw-dump 2>/dev/null | jq -r \
            '[.[] | select(.info.props["application.process.binary"]? == "tidal-hifi"
                       and .info.props["media.class"]? == "Stream/Output/Audio")]
             | first | .id // empty'
    elif [ "$player" = "spotify" ]; then
        pw-dump 2>/dev/null | jq -r \
            '[.[] | select(.info.props["application.name"]? == "spotify"
                       and .info.props["media.class"]? == "Stream/Output/Audio")]
             | first | .id // empty'
    fi
}

# Return the sample rate of the player's audio stream.
# Tidal streams at 48 kHz (including Dolby Atmos); Spotify at 44.1 kHz.
# Detects the actual rate from PipeWire when possible.
get_player_sample_rate() {
    local player="${1:-$(get_active_player)}"
    local default_rate=48000
    [ "$player" = "spotify" ] && default_rate=44100

    local node_id
    node_id=$(get_player_pw_node "$player")
    if [ -n "$node_id" ]; then
        local rate
        rate=$(pw-dump "$node_id" 2>/dev/null \
            | jq -r '.[0].info.params.Format[0].rate // empty' 2>/dev/null)
        if [ -n "$rate" ] && [ "$rate" -gt 0 ] 2>/dev/null; then
            echo "$rate"
            return
        fi
    fi
    echo "$default_rate"
}
