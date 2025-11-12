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

        # Web apps
        chrome-github*|github)
            printf '\uf09b' ;;  # nf-fa-github
        chrome-figma*|figma)
            printf '\uf94c' ;;  # nf-mdi-graph
        chrome-x.com*|x)
            printf '\uf099' ;;  # nf-fa-twitter
        chrome-*hey.com*|hey|email)
            printf '\uf0e0' ;;  # nf-fa-envelope
        chrome-youtube*|youtube)
            printf '\uf167' ;;  # nf-fa-youtube
        chrome-whatsapp*|whatsapp)
            printf '\uf232' ;;  # nf-fa-whatsapp
        chrome-photos.google*|photos)
            printf '\uf03e' ;;  # nf-fa-photo
        chrome-messages.google*|messages)
            printf '\uf27a' ;;  # nf-fa-comment
        chrome-grok*|grok)
            printf '\uf544' ;;  # nf-fa-robot

        # Code editors
        code|vscode|*visual*studio*code*)
            printf '\ue70c' ;;  # nf-dev-visualstudio (correct VSCode icon)
        cursor)
            printf '\ue70c' ;;  # nf-dev-visualstudio (using VSCode icon as similar)
        zed)
            printf '\uf121' ;;  # nf-fa-code

        # Note-taking - using note icon as placeholder
        obsidian)
            printf '\uf5e7' ;;  # nf-fa-sticky_note (placeholder, closest match)

        # Design/Drawing
        *draw*|drawio)
            printf '\uf1fc' ;;  # nf-fa-paint_brush
        figma)
            printf '\uf94c' ;;  # nf-mdi-graph
        inkscape)
            printf '\uf5e7' ;;  # nf-fa-sticky_note

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
