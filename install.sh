#!/usr/bin/env bash
# ==============================================================================
# Dotfiles Installation Script
# ==============================================================================
# This script sets up a new Arch Linux system with Hyprland and all custom
# configurations for a complete working environment.
#
# Usage: ./install.sh [options]
#   --skip-packages    Skip package installation
#   --skip-links       Skip creating symlinks
#   --help             Show this help message
# ==============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Parse arguments
SKIP_PACKAGES=false
SKIP_LINKS=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-packages)
            SKIP_PACKAGES=true
            shift
            ;;
        --skip-links)
            SKIP_LINKS=true
            shift
            ;;
        --help)
            grep "^#" "$0" | grep -v "^#!/" | sed 's/^# //'
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            exit 1
            ;;
    esac
done

# Helper functions
print_header() {
    echo -e "\n${BLUE}==>${NC} ${GREEN}$1${NC}"
}

print_info() {
    echo -e "${BLUE}  ->${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

# Check if running on Arch Linux
check_system() {
    print_header "Checking system..."

    if [[ ! -f /etc/arch-release ]]; then
        print_error "This script is designed for Arch Linux"
        exit 1
    fi

    print_success "Running on Arch Linux"
}

# Install required packages
install_packages() {
    if [[ "$SKIP_PACKAGES" == true ]]; then
        print_warning "Skipping package installation"
        return
    fi

    print_header "Installing required packages..."

    # Core packages
    local packages=(
        # Hyprland and compositor
        hyprland
        hypridle
        hyprlock
        hyprsunset

        # Waybar and dependencies
        waybar

        # Terminal and shell
        alacritty
        bash

        # System utilities
        btop
        fastfetch

        # Fonts (for Waybar icons)
        nerd-fonts

        # Other utilities
        jq              # JSON processing for scripts
        bc              # Calculator for scripts
    )

    print_info "Installing ${#packages[@]} packages..."

    if ! sudo pacman -S --needed --noconfirm "${packages[@]}"; then
        print_error "Failed to install some packages"
        exit 1
    fi

    print_success "Packages installed successfully"
}

# Install Omarchy (Hyprland configuration framework)
install_omarchy() {
    print_header "Setting up Omarchy..."

    if [[ -d ~/.local/share/omarchy ]]; then
        print_warning "Omarchy already installed, skipping"
        return
    fi

    print_info "Installing Omarchy..."

    # Install Omarchy (adjust this based on actual installation method)
    # This is a placeholder - you may need to update this with the actual installation command
    if command -v omarchy &> /dev/null; then
        print_success "Omarchy already available"
    else
        print_warning "Omarchy not found. Please install it manually from:"
        print_info "https://github.com/omarchy/omarchy"
    fi
}

# Create symlinks
create_symlinks() {
    if [[ "$SKIP_LINKS" == true ]]; then
        print_warning "Skipping symlink creation"
        return
    fi

    print_header "Creating symlinks..."

    # Backup function
    backup_if_exists() {
        if [[ -e "$1" ]] && [[ ! -L "$1" ]]; then
            local backup="$1.backup.$(date +%Y%m%d_%H%M%S)"
            print_info "Backing up $1 to $backup"
            mv "$1" "$backup"
        fi
    }

    # Hyprland configuration
    print_info "Linking Hyprland configuration..."
    mkdir -p ~/.config/hypr
    for file in "$SCRIPT_DIR/hypr"/*.conf; do
        filename=$(basename "$file")
        backup_if_exists ~/.config/hypr/"$filename"
        ln -sf "$file" ~/.config/hypr/"$filename"
    done

    # Waybar configuration
    print_info "Linking Waybar configuration..."
    mkdir -p ~/.config/waybar/scripts
    backup_if_exists ~/.config/waybar/config.jsonc
    backup_if_exists ~/.config/waybar/style.css
    ln -sf "$SCRIPT_DIR/waybar/config.jsonc" ~/.config/waybar/config.jsonc
    ln -sf "$SCRIPT_DIR/waybar/style.css" ~/.config/waybar/style.css

    for script in "$SCRIPT_DIR/waybar/scripts"/*; do
        scriptname=$(basename "$script")
        ln -sf "$script" ~/.config/waybar/scripts/"$scriptname"
        chmod +x ~/.config/waybar/scripts/"$scriptname"
    done

    # Shell configuration
    print_info "Linking shell configuration..."
    backup_if_exists ~/.bashrc
    backup_if_exists ~/.bash_profile
    ln -sf "$SCRIPT_DIR/shell/bashrc" ~/.bashrc
    ln -sf "$SCRIPT_DIR/shell/bash_profile" ~/.bash_profile

    print_success "Symlinks created successfully"
}

# Post-installation steps
post_install() {
    print_header "Post-installation steps..."

    print_info "To complete the setup:"
    echo ""
    echo "  1. Log out and log back in (or reboot) to start Hyprland"
    echo "  2. Review and adjust monitor configuration in ~/.config/hypr/monitors.conf"
    echo "  3. Check ~/.config/hypr/bindings.conf for keybindings"
    echo "  4. Waybar should start automatically with custom modules"
    echo "  5. Hyprsunset will manage screen color temperature automatically"
    echo ""
    echo "Documentation available in: $SCRIPT_DIR/docs/"
    echo ""

    print_success "Installation complete!"
}

# Main installation flow
main() {
    echo -e "${GREEN}"
    echo "╔═══════════════════════════════════════════════════════╗"
    echo "║                                                       ║"
    echo "║        Dotfiles Installation Script                  ║"
    echo "║        Arch Linux + Hyprland Setup                   ║"
    echo "║                                                       ║"
    echo "╚═══════════════════════════════════════════════════════╝"
    echo -e "${NC}"

    check_system
    install_packages
    install_omarchy
    create_symlinks
    post_install

    echo -e "\n${GREEN}All done! 🎉${NC}\n"
}

# Run main function
main "$@"
