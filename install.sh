#!/usr/bin/env bash
# ==============================================================================
# Modular Dotfiles Installation Script
# ==============================================================================
# This script sets up a new Arch Linux system with Hyprland and allows
# selective installation of Waybar modules.
#
# Usage: ./install.sh [options]
#   --modules=MODULE1,MODULE2  Install specific modules (comma-separated)
#   --skip-packages            Skip package installation
#   --skip-links               Skip creating symlinks
#   --update                   Update existing installation
#   --list-modules             List available modules
#   --help                     Show this help message
# ==============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULES_CONF="$SCRIPT_DIR/modules.conf"
INSTALLED_MODULES_FILE="$HOME/.config/waybar/.installed_modules"

# Script arguments (will be parsed after function definitions)
SKIP_PACKAGES=false
SKIP_LINKS=false
UPDATE_MODE=false
INTERACTIVE=true
SELECTED_MODULES=()

# Helper functions
print_header() {
    echo -e "\n${BLUE}==>${NC} ${GREEN}$1${NC}"
}

print_subheader() {
    echo -e "\n${CYAN}  ►${NC} ${MAGENTA}$1${NC}"
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

# Read modules configuration
declare -A MODULE_DESCRIPTIONS
declare -A MODULE_SCRIPTS
declare -A MODULE_CONFIG_SECTIONS
declare -A MODULE_STYLE_SECTIONS
declare -A MODULE_DEPENDENCIES

load_modules_config() {
    if [[ ! -f "$MODULES_CONF" ]]; then
        print_error "modules.conf not found!"
        exit 1
    fi

    local current_module=""
    while IFS= read -r line || [[ -n "$line" ]]; do
        # Skip comments and empty lines
        [[ "$line" =~ ^#.*$ ]] && continue
        [[ -z "$line" ]] && continue

        # Module header
        if [[ "$line" =~ ^\[([A-Z_]+)\]$ ]]; then
            current_module="${BASH_REMATCH[1]}"
            continue
        fi

        # Module properties
        if [[ -n "$current_module" ]]; then
            if [[ "$line" =~ ^description:\ (.+)$ ]]; then
                MODULE_DESCRIPTIONS[$current_module]="${BASH_REMATCH[1]}"
            elif [[ "$line" =~ ^scripts:\ (.+)$ ]]; then
                MODULE_SCRIPTS[$current_module]="${BASH_REMATCH[1]}"
            elif [[ "$line" =~ ^config_sections:\ (.+)$ ]]; then
                MODULE_CONFIG_SECTIONS[$current_module]="${BASH_REMATCH[1]}"
            elif [[ "$line" =~ ^style_sections:\ (.+)$ ]]; then
                MODULE_STYLE_SECTIONS[$current_module]="${BASH_REMATCH[1]}"
            elif [[ "$line" =~ ^dependencies:\ (.*)$ ]]; then
                MODULE_DEPENDENCIES[$current_module]="${BASH_REMATCH[1]}"
            fi
        fi
    done < "$MODULES_CONF"
}

# List available modules
list_modules() {
    load_modules_config
    echo -e "${GREEN}Available Modules:${NC}\n"
    for module in "${!MODULE_DESCRIPTIONS[@]}"; do
        echo -e "${CYAN}${module}${NC}"
        echo -e "  ${MODULE_DESCRIPTIONS[$module]}"
        echo ""
    done
}

# Get installed modules
get_installed_modules() {
    if [[ -f "$INSTALLED_MODULES_FILE" ]]; then
        cat "$INSTALLED_MODULES_FILE"
    fi
}

# Save installed modules
save_installed_modules() {
    mkdir -p "$(dirname "$INSTALLED_MODULES_FILE")"
    printf "%s\n" "${SELECTED_MODULES[@]}" > "$INSTALLED_MODULES_FILE"
}

# Interactive module selection
interactive_module_selection() {
    print_header "Module Selection"

    echo -e "\n${CYAN}Available modules:${NC}\n"
    echo -e "  ${GREEN}1)${NC} Everything (install all modules)"

    local i=2
    local module_list=()
    for module in "${!MODULE_DESCRIPTIONS[@]}"; do
        module_list+=("$module")
        echo -e "  ${GREEN}${i})${NC} ${CYAN}${module}${NC}"
        echo -e "     ${MODULE_DESCRIPTIONS[$module]}"
        ((i++))
    done

    echo -e "\n${YELLOW}Enter your choices (e.g., 1 or 2,3,4 or 1-4):${NC}"
    read -r choices

    # Parse choices
    if [[ "$choices" == "1" ]]; then
        SELECTED_MODULES=("EVERYTHING" "${module_list[@]}")
    else
        # Handle ranges (1-4) and comma-separated (2,3,4)
        choices=$(echo "$choices" | tr ',' ' ')
        for choice in $choices; do
            if [[ "$choice" =~ ^([0-9]+)-([0-9]+)$ ]]; then
                # Range
                start=${BASH_REMATCH[1]}
                end=${BASH_REMATCH[2]}
                for ((j=start; j<=end; j++)); do
                    if [[ $j -eq 1 ]]; then
                        SELECTED_MODULES=("EVERYTHING" "${module_list[@]}")
                        break 2
                    elif [[ $j -ge 2 && $j -lt $((${#module_list[@]} + 2)) ]]; then
                        SELECTED_MODULES+=("${module_list[$((j-2))]}")
                    fi
                done
            else
                # Single choice
                if [[ "$choice" -eq 1 ]]; then
                    SELECTED_MODULES=("EVERYTHING" "${module_list[@]}")
                    break
                elif [[ "$choice" -ge 2 && "$choice" -lt $((${#module_list[@]} + 2)) ]]; then
                    SELECTED_MODULES+=("${module_list[$((choice-2))]}")
                fi
            fi
        done
    fi

    # Remove duplicates
    SELECTED_MODULES=($(printf "%s\n" "${SELECTED_MODULES[@]}" | sort -u))

    # Remove "EVERYTHING" marker if present
    SELECTED_MODULES=("${SELECTED_MODULES[@]/EVERYTHING/}")

    echo -e "\n${GREEN}Selected modules:${NC}"
    for module in "${SELECTED_MODULES[@]}"; do
        [[ -z "$module" ]] && continue
        echo -e "  ${CYAN}•${NC} ${module}"
    done

    echo -e "\n${YELLOW}Proceed with installation? (y/n):${NC}"
    read -r confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo -e "${RED}Installation cancelled${NC}"
        exit 0
    fi
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

    if command -v omarchy &> /dev/null; then
        print_success "Omarchy already available"
    else
        print_warning "Omarchy not found. Please install it manually from:"
        print_info "https://github.com/omarchy/omarchy"
    fi
}

# Create base symlinks (Hyprland, shell)
create_base_symlinks() {
    if [[ "$SKIP_LINKS" == true ]]; then
        print_warning "Skipping symlink creation"
        return
    fi

    print_header "Creating base symlinks..."

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
        [[ -f "$file" ]] || continue
        filename=$(basename "$file")
        backup_if_exists ~/.config/hypr/"$filename"
        ln -sf "$file" ~/.config/hypr/"$filename"
    done

    # Shell configuration
    if [[ -d "$SCRIPT_DIR/shell" ]]; then
        print_info "Linking shell configuration..."
        backup_if_exists ~/.bashrc
        backup_if_exists ~/.bash_profile
        [[ -f "$SCRIPT_DIR/shell/bashrc" ]] && ln -sf "$SCRIPT_DIR/shell/bashrc" ~/.bashrc
        [[ -f "$SCRIPT_DIR/shell/bash_profile" ]] && ln -sf "$SCRIPT_DIR/shell/bash_profile" ~/.bash_profile
    fi

    print_success "Base symlinks created successfully"
}

# Install selected Waybar modules
install_waybar_modules() {
    print_header "Installing Waybar modules..."

    mkdir -p ~/.config/waybar/scripts

    # Link base Waybar files (config.jsonc and style.css)
    print_info "Linking base Waybar configuration..."
    backup_if_exists() {
        if [[ -e "$1" ]] && [[ ! -L "$1" ]]; then
            local backup="$1.backup.$(date +%Y%m%d_%H%M%S)"
            print_info "Backing up $1 to $backup"
            mv "$1" "$backup"
        fi
    }

    backup_if_exists ~/.config/waybar/config.jsonc
    backup_if_exists ~/.config/waybar/style.css
    ln -sf "$SCRIPT_DIR/waybar/config.jsonc" ~/.config/waybar/config.jsonc
    ln -sf "$SCRIPT_DIR/waybar/style.css" ~/.config/waybar/style.css

    # Install each selected module
    for module in "${SELECTED_MODULES[@]}"; do
        [[ -z "$module" ]] && continue
        print_subheader "Installing $module"

        # Link scripts
        local scripts="${MODULE_SCRIPTS[$module]}"
        if [[ -n "$scripts" ]]; then
            for script in $scripts; do
                local script_path="$SCRIPT_DIR/waybar/scripts/$script"
                if [[ -f "$script_path" ]]; then
                    ln -sf "$script_path" ~/.config/waybar/scripts/"$script"
                    chmod +x ~/.config/waybar/scripts/"$script"
                    print_info "Linked script: $script"
                else
                    print_warning "Script not found: $script"
                fi
            done
        fi

        print_success "$module installed"
    done

    save_installed_modules
    print_success "All modules installed successfully"
}

# Update existing installation
update_installation() {
    print_header "Updating existing installation..."

    if [[ ! -f "$INSTALLED_MODULES_FILE" ]]; then
        print_error "No previous installation found. Use regular install instead."
        exit 1
    fi

    # Read previously installed modules
    mapfile -t SELECTED_MODULES < "$INSTALLED_MODULES_FILE"

    echo -e "\n${CYAN}Previously installed modules:${NC}"
    for module in "${SELECTED_MODULES[@]}"; do
        echo -e "  ${GREEN}•${NC} ${module}"
    done

    echo -e "\n${YELLOW}Do you want to:${NC}"
    echo -e "  ${GREEN}1)${NC} Update these modules"
    echo -e "  ${GREEN}2)${NC} Add/remove modules"
    echo -e "  ${GREEN}3)${NC} Cancel"
    read -r choice

    case "$choice" in
        1)
            print_info "Updating existing modules..."
            ;;
        2)
            interactive_module_selection
            ;;
        *)
            echo -e "${RED}Update cancelled${NC}"
            exit 0
            ;;
    esac

    # Re-link everything
    install_waybar_modules

    print_success "Update complete!"
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
    echo "To update your installation later, run: ./install.sh --update"
    echo ""

    print_success "Installation complete!"
}

# Parse command-line arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --modules=*)
                INTERACTIVE=false
                IFS=',' read -ra SELECTED_MODULES <<< "${1#*=}"
                shift
                ;;
            --skip-packages)
                SKIP_PACKAGES=true
                shift
                ;;
            --skip-links)
                SKIP_LINKS=true
                shift
                ;;
            --update)
                UPDATE_MODE=true
                shift
                ;;
            --list-modules)
                load_modules_config
                list_modules
                exit 0
                ;;
            --help)
                grep "^#" "$0" | head -15 | grep -v "^#!/" | sed 's/^# //'
                exit 0
                ;;
            *)
                echo -e "${RED}Unknown option: $1${NC}"
                exit 1
                ;;
        esac
    done
}

# Main installation flow
main() {
    echo -e "${GREEN}"
    echo "╔═══════════════════════════════════════════════════════╗"
    echo "║                                                       ║"
    echo "║        Modular Dotfiles Installation Script          ║"
    echo "║        Arch Linux + Hyprland Setup                   ║"
    echo "║                                                       ║"
    echo "╚═══════════════════════════════════════════════════════╝"
    echo -e "${NC}"

    # Load module definitions
    load_modules_config

    # Check if this is an update
    if [[ "$UPDATE_MODE" == true ]]; then
        update_installation
        exit 0
    fi

    # System checks
    check_system

    # Module selection
    if [[ "$INTERACTIVE" == true ]]; then
        interactive_module_selection
    else
        # Validate provided modules
        for module in "${SELECTED_MODULES[@]}"; do
            if [[ -z "${MODULE_DESCRIPTIONS[$module]}" ]]; then
                print_error "Unknown module: $module"
                echo "Run './install.sh --list-modules' to see available modules"
                exit 1
            fi
        done
    fi

    # Installation steps
    install_packages
    install_omarchy
    create_base_symlinks
    install_waybar_modules
    post_install

    echo -e "\n${GREEN}All done! 🎉${NC}\n"
}

# Parse arguments and run main
parse_arguments "$@"
main
