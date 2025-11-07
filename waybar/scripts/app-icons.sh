#!/usr/bin/env bash
# Icon mapping helper - returns Nerd Font icon for app class
# Note: Waybar custom modules don't support image files in text output

get_icon_for_app() {
    local app="$1"
    local app_lower=$(echo "$app" | tr '[:upper:]' '[:lower:]')

    case "$app_lower" in
        # Browsers
        chromium|chrome|google-chrome)
            printf '\uf268' ;;  # nf-fa-chrome (correct Chrome icon)
        firefox)
            printf '\uf269' ;;  # nf-fa-firefox (correct Firefox icon)

        # AI/Chat apps - using robot icon as placeholder
        chrome-chatgpt*|chatgpt*)
            printf '\uf544' ;;  # nf-fa-robot (placeholder until we find OpenAI icon)

        # Code editors
        code|vscode)
            printf '\ue70c' ;;  # nf-dev-visualstudio (correct VSCode icon)

        # Note-taking - using note icon as placeholder
        obsidian)
            printf '\uf5e7' ;;  # nf-fa-sticky_note (placeholder, closest match)

        # Terminals
        alacritty|kitty|terminal|foot|wezterm)
            printf '\uf120' ;;  # nf-fa-terminal

        # Media & Social
        spotify)
            printf '\uf1bc' ;;  # nf-fa-spotify (correct Spotify icon)
        discord)
            printf '\uf392' ;;  # nf-mdi-discord (correct Discord icon)
        slack)
            printf '\uf198' ;;  # nf-fa-slack (correct Slack icon)

        # Other apps
        thunderbird|mail)
            printf '\uf0e0' ;;  # nf-fa-envelope
        nautilus|thunar|dolphin|nemo|pcmanfm)
            printf '\uf07b' ;;  # nf-fa-folder
        gimp)
            printf '\uf1c5' ;;  # nf-fa-file_image_o
        vlc|mpv)
            printf '\uf03d' ;;  # nf-fa-film
        steam)
            printf '\uf1b6' ;;  # nf-fa-steam (correct Steam icon)
        btop|htop|top)
            printf '\uf080' ;;  # nf-fa-bar_chart
        bjorn)
            printf '\uf013' ;;  # nf-fa-cog
        *)
            printf '\uf2d0' ;;  # nf-fa-window_maximize (default)
    esac
}

get_icon_for_app "$@"
