# GHyprland - Theme-Agnostic Hyprland Configuration

A comprehensive Hyprland configuration that works seamlessly with any theme, featuring advanced Waybar modules and a research-based circadian rhythm color temperature system.

## Features

### Hyprland Configuration
- Modular configuration based on [Omarchy](https://github.com/omarchy/omarchy)
- Custom monitor setup
- Personalized keybindings and window rules
- Integrated with hypridle, hyprlock, and hyprsunset

### Waybar Setup
- **Multi-monitor configuration** with different content per display
- **Dynamic workspace management** (1-12 workspaces):
  - Workspaces 1-4: Always visible (core workspaces)
  - Workspaces 5-12: Auto-show when occupied, auto-hide when empty
  - "+" button to create new workspaces on-demand
  - Dynamic Island styling with app icons
- **System monitoring modules**:
  - CPU usage with rolling average and top processes tooltip
  - GPU usage (AMD RX 9070) with temperature and VRAM monitoring
  - RAM usage with top processes tooltip
  - GPU electricity cost tracker (configurable rate)
- **Pomodoro timer** with 25/5/15 minute cycles
- **Update indicator** and screen recording indicator

### Hyprsunset (Blue Light Filter)
Research-based color temperature management:
- **Morning transition** (07:00-11:00): 2700K → 6500K (mimics natural sunrise)
- **Daytime** (11:00-19:00): 6500K peak alertness
- **Evening transition** (19:00-22:30): 4500K → 2500K (prepares for sleep)
- **Night** (22:30-07:00): 2500K optimal sleep temperature

Based on CDC/NIOSH research and academic studies on circadian rhythms and melatonin production.

## Screenshots

*(Add screenshots here after setup)*

## Quick Start

### Prerequisites

- Arch Linux (or Arch-based distribution)
- Git

### Installation

> **🎉 New in v2.0:** Modular installation system! Install only the modules you need. See [MODULAR_INSTALL.md](MODULAR_INSTALL.md) for full documentation.

1. **Clone the repository**

```bash
git clone https://github.com/YOUR_USERNAME/GHyprland.git ~/Repos/GHyprland
cd ~/Repos/GHyprland
```

2. **Run the installation script**

```bash
./install.sh
```

The script will prompt you to select which Waybar modules to install:

**Available modules:**
- **Everything** - Install all modules
- **WORKSPACE** - Dynamic workspace management with app icons (1-12 workspaces + add button)
- **POMODORO** - Pomodoro timer with collapsible controls (25/5/15 cycles)
- **SYSTEM_METRICS** - System monitoring (CPU, GPU, RAM) with rolling averages
- **SPOTIFY_LITE** - Spotify control with playback controls

The installer will:
- Install required packages via pacman
- Set up Omarchy (Hyprland configuration framework)
- Create symlinks for selected modules
- Backup existing configurations
- Track installed modules for future updates

### Advanced Installation Options

```bash
# List available modules
./install.sh --list-modules

# Non-interactive: install specific modules
./install.sh --modules=WORKSPACE,POMODORO,SYSTEM_METRICS

# Install everything
./install.sh --modules=WORKSPACE,POMODORO,SYSTEM_METRICS,SPOTIFY_LITE

# Install packages only (skip symlinks)
./install.sh --skip-links

# Create symlinks only (packages already installed)
./install.sh --skip-packages

# Show help
./install.sh --help
```

### Updating Your Installation

After making changes or pulling updates:

```bash
cd ~/Repos/GHyprland
git pull origin main
./install.sh --update
```

The update will:
1. Show your currently installed modules
2. Offer to update them or change the selection
3. Re-link all scripts to get the latest versions

See [MODULAR_INSTALL.md](MODULAR_INSTALL.md) for detailed documentation on the modular system.

## Repository Structure

```
GHyprland/
├── hypr/                   # Hyprland configuration files
│   ├── hyprland.conf       # Main config (sources Omarchy + custom)
│   ├── monitors.conf       # Monitor setup
│   ├── bindings.conf       # Keybindings
│   ├── autostart.conf      # Autostart applications
│   ├── hyprsunset.conf     # Color temperature schedule
│   └── ...
├── waybar/                 # Waybar configuration
│   ├── config.jsonc        # Waybar module configuration
│   ├── style.css           # Waybar styling
│   └── scripts/            # Custom module scripts
│       ├── workspace-single.sh    # Individual workspace display (1-12)
│       ├── workspace-add.sh       # "+" button for adding workspaces
│       ├── app-icons.sh           # App icon mapping
│       ├── cpu.sh
│       ├── gpu.sh
│       ├── gpu-icon.sh
│       ├── ram.sh
│       ├── power.sh
│       ├── pomodoro.sh
│       ├── pomodoro-icon.sh
│       ├── pomodoro-play.sh
│       ├── pomodoro-skip.sh
│       ├── spotify.sh
│       ├── spotify-icon.sh
│       ├── spotify-prev.sh
│       ├── spotify-play.sh
│       ├── spotify-next.sh
│       └── workspaces.sh
├── shell/                  # Shell configuration
│   ├── bashrc
│   └── bash_profile
├── docs/                   # Documentation
├── modules.conf            # Module definitions (NEW in v2.0)
├── install.sh              # Modular installation script
├── MODULAR_INSTALL.md      # Modular system documentation
├── CHANGELOG.md            # Version history
└── README.md               # This file
```

## Post-Installation

After running the installation script:

1. **Log out and log back in** to start Hyprland
2. **Adjust monitor configuration** if needed:
   ```bash
   nano ~/.config/hypr/monitors.conf
   ```
3. **Review keybindings**:
   ```bash
   cat ~/.config/hypr/bindings.conf
   ```
4. **Configure Waybar modules** (optional):
   - Adjust electricity rate in `~/.config/waybar/scripts/power.sh`
   - Modify Pomodoro timer durations in `~/.config/waybar/scripts/pomodoro.sh`
   - Customize workspace app icons in `~/.config/waybar/scripts/app-icons.sh`

## Customization

### Waybar

#### Changing Electricity Rate
Edit `~/.config/waybar/scripts/power.sh`:
```bash
COST_PER_KWH=0.35  # Change to your rate
```

#### Modifying Pomodoro Timer
Edit `~/.config/waybar/scripts/pomodoro.sh`:
```bash
WORK_TIME=1500        # 25 minutes
SHORT_BREAK=300       # 5 minutes
LONG_BREAK=900        # 15 minutes
```

#### Adding Application Icons
Edit `~/.config/waybar/scripts/app-icons.sh` to map application classes to Nerd Font icons.

### Hyprsunset

To adjust color temperature schedule, edit `~/.config/hypr/hyprsunset.conf`:
```bash
profile {
    time = 19:00
    temperature = 4500  # Lower = warmer, Higher = cooler
}
```

Reload after changes:
```bash
pkill hyprsunset && hyprsunset &
```

### Hyprland

All Hyprland customizations should be made in `~/.config/hypr/*.conf` files, not in the Omarchy defaults.

## Documentation

Comprehensive guides are available in the `docs/` directory:

- **[Dynamic Workspace Management](waybar/WORKSPACE.md)**: Complete guide to the intelligent 12-workspace system with auto-show/hide behavior
- **[Hyprsunset Configuration](docs/Linux%20Arch/Hypr/Hyprsunset%20Configuration.md)**: Detailed explanation of the color temperature system, research basis, and customization
- **[Waybar Configuration](docs/Linux%20Arch/Waybar/Waybar%20Configuration.md)**: Complete documentation of all Waybar modules, custom scripts, and troubleshooting
- **[GPU Monitoring](waybar/GPU_MONITORING.md)**: Multi-vendor GPU monitoring setup and configuration

## Keybindings

Key default bindings (see `~/.config/hypr/bindings.conf` for complete list):

- `SUPER + Return`: Launch terminal
- `SUPER + Q`: Close window
- `SUPER + [1-6]`: Switch to workspace 1-6
- `SUPER + SHIFT + [1-6]`: Move window to workspace 1-6
- `SUPER + F`: Toggle fullscreen
- `SUPER + Space`: Toggle floating

**Note:** Workspaces 5-12 are accessible via the waybar "+" button or by moving windows to them programmatically. Workspaces 1-4 are always visible.

## Hardware Specific Notes

### GPU Monitoring
The Waybar GPU module is configured for **AMD Radeon RX 9070 (card1)**. If you have different hardware:

1. Find your GPU device:
   ```bash
   ls /sys/class/drm/
   ```
2. Edit `~/.config/waybar/scripts/gpu.sh` and update the paths accordingly

### Multi-Monitor Setup
Current setup uses DP-1 and DP-2. Adjust in `~/.config/hypr/monitors.conf` for your setup.

## Updating

To update your configuration:

```bash
cd ~/GHyprland
git pull
./install.sh --skip-packages  # Refresh symlinks only
```

## Troubleshooting

### Waybar not showing custom modules
```bash
# Restart Waybar
killall waybar && waybar &

# Check for errors
waybar > /tmp/waybar.log 2>&1
cat /tmp/waybar.log
```

### Hyprsunset not applying
```bash
# Check if running
ps aux | grep hyprsunset

# Restart
pkill hyprsunset && hyprsunset &
```

### GPU module shows "N/A"
Verify sysfs paths are accessible:
```bash
cat /sys/class/drm/card1/device/gpu_busy_percent
cat /sys/class/drm/card1/device/mem_info_vram_used
```

## Contributing

This is a personal Hyprland configuration repository, but feel free to:
- Open issues for questions or suggestions
- Fork and adapt for your own setup
- Submit PRs for bug fixes

## License

MIT License - Feel free to use and modify as needed.

## Acknowledgments

- [Hyprland](https://hyprland.org/) - Amazing Wayland compositor
- [Omarchy](https://github.com/omarchy/omarchy) - Hyprland configuration framework
- [Waybar](https://github.com/Alexays/Waybar) - Highly customizable Wayland bar
- Research on circadian rhythms from CDC/NIOSH

## Resources

- [Hyprland Wiki](https://wiki.hyprland.org/)
- [Waybar Wiki](https://github.com/Alexays/Waybar/wiki)
- [Nerd Fonts](https://www.nerdfonts.com/) - Icon fonts used in Waybar
- [Arch Wiki](https://wiki.archlinux.org/)
