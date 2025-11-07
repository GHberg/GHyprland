#!/usr/bin/env bash
# Icon mapping helper - returns Nerd Font icon for app class
# Note: Waybar custom modules don't support image files in text output

get_icon_for_app() {
    local app="$1"
    local app_lower=$(echo "$app" | tr '[:upper:]' '[:lower:]')

    case "$app_lower" in
        # Browsers & Web Apps
        chromium|chrome|google-chrome)
            printf '\uf268' ;;  # nf-fa-chrome (correct Chrome icon)
        firefox)
            printf '\uf269' ;;  # nf-fa-firefox (correct Firefox icon)
        chrome-youtube*|youtube*)
            printf '\uf167' ;;  # nf-fa-youtube_play (YouTube icon)
        chrome-maps.google*|*googlemaps*)
            printf '\uf279' ;;  # nf-fa-map (Google Maps)
        chrome-www.openstreetmap*|openstreetmap*)
            printf '\uf279' ;;  # nf-fa-map (OpenStreetMap)
        chrome-figma*|figma*)
            printf '\uf1fc' ;;  # nf-fa-paint_brush (Figma design tool)
        1password|com.1password.1password)
            printf '\uf023' ;;  # nf-fa-lock (1Password)

        # AI/Chat apps - using robot icon as placeholder
        chrome-chatgpt*|chatgpt*)
            printf '\uf544' ;;  # nf-fa-robot (placeholder until we find OpenAI icon)

        # Code editors & Development
        code|vscode)
            printf '\ue70c' ;;  # nf-dev-visualstudio (correct VSCode icon)
        neovim|nvim)
            printf '\ue62b' ;;  # nf-dev-vim (Neovim icon)
        docker)
            printf '\uf308' ;;  # nf-dev-docker (Docker icon)
        chrome-github*|github*)
            printf '\uf09b' ;;  # nf-fa-github (GitHub icon)

        # Note-taking & Productivity
        obsidian)
            printf '\uf5e7' ;;  # nf-fa-sticky_note (placeholder, closest match)
        typora)
            printf '\uf15c' ;;  # nf-fa-file_text (Typora markdown editor)
        xournal++|xournalpp)
            printf '\uf304' ;;  # nf-fa-pencil_square (Xournal++ notes)
        chrome-basecamp*|basecamp*)
            printf '\uf0c0' ;;  # nf-fa-users (Basecamp project management)

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
        signal)
            printf '\uf3ed' ;;  # nf-fa-commenting (Signal messaging)
        chrome-web.whatsapp*|whatsapp*)
            printf '\uf232' ;;  # nf-fa-whatsapp (WhatsApp icon)
        zoom|zoom.us)
            printf '\uf03d' ;;  # nf-fa-video_camera (Zoom video calls)
        chrome-app.hey.com*|hey*)
            printf '\uf0e0' ;;  # nf-fa-envelope (HEY email)

        # LibreOffice Suite
        libreoffice-writer|writer)
            printf '\uf1c2' ;;  # nf-fa-file_text_o (Writer documents)
        libreoffice-calc|calc)
            printf '\uf1c3' ;;  # nf-fa-file_excel_o (Calc spreadsheets)
        libreoffice-impress|impress)
            printf '\uf1c4' ;;  # nf-fa-file_powerpoint_o (Impress presentations)
        libreoffice-draw|draw)
            printf '\uf1fc' ;;  # nf-fa-paint_brush (Draw graphics)
        libreoffice-base|base)
            printf '\uf1c0' ;;  # nf-fa-database (Base database)
        libreoffice-math|math)
            printf '\uf698' ;;  # nf-fa-square_root_alt (Math formulas)

        # Media Players & Tools
        vlc)
            printf '\uf03d' ;;  # nf-fa-film (VLC)
        mpv)
            printf '\uf03d' ;;  # nf-fa-film (mpv)
        obs|com.obsproject.studio)
            printf '\uf03d' ;;  # nf-fa-video_camera (OBS Studio)
        kdenlive|org.kde.kdenlive)
            printf '\uf008' ;;  # nf-fa-film (Kdenlive video editor)
        imv)
            printf '\uf03e' ;;  # nf-fa-image (imv image viewer)
        evince|org.gnome.evince|atril)
            printf '\uf1c1' ;;  # nf-fa-file_pdf_o (Document Viewer)

        # Graphics & Design
        gimp)
            printf '\uf1c5' ;;  # nf-fa-file_image_o
        pinta|pinta.pinta)
            printf '\uf1fc' ;;  # nf-fa-paint_brush (Pinta)
        satty)
            printf '\uf040' ;;  # nf-fa-pencil (Satty screenshot editor)

        # Utilities
        thunderbird|mail)
            printf '\uf0e0' ;;  # nf-fa-envelope
        nautilus|thunar|dolphin|nemo|pcmanfm|org.gnome.nautilus)
            printf '\uf07b' ;;  # nf-fa-folder
        gnome-calculator|org.gnome.calculator|kcalc|calculator)
            printf '\uf1ec' ;;  # nf-fa-calculator (Calculator)
        gnome-disks|org.gnome.disks|gparted)
            printf '\uf0a0' ;;  # nf-fa-hdd_o (Disks)
        localsend|org.localsend.localsend_app)
            printf '\uf1e0' ;;  # nf-fa-share_alt (LocalSend file sharing)
        gnome-disk-image-mounter|gnome-disk-image-writer)
            printf '\uf0c7' ;;  # nf-fa-save (Disk Image tools)
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
