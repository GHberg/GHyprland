# Modular Installation System

## Overview

The dotfiles repository now supports **modular installation**, allowing you to selectively install Waybar modules instead of requiring a full installation. This makes it easy to:

- Install only the modules you need
- Add new modules to an existing installation
- Update modules across multiple machines
- Test new modules without affecting your current setup

## Quick Start

### List Available Modules

```bash
./install.sh --list-modules
```

### Interactive Installation (Recommended)

```bash
./install.sh
```

You'll be prompted to select which modules to install:

```
Available modules:

  1) Everything (install all modules)
  2) WORKSPACE
     Dynamic workspace indicators with app icons (1-6)
  3) POMODORO
     Pomodoro timer with collapsible controls (25/5/15 cycles)
  4) SYSTEM_METRICS
     System monitoring (CPU, GPU, RAM) with rolling averages
  5) SPOTIFY_LITE
     Spotify control with playback controls (lite version)

Enter your choices (e.g., 1 or 2,3,4 or 1-4):
```

**Selection options:**
- `1` - Install everything
- `2,4,5` - Install specific modules (comma-separated)
- `2-5` - Install a range of modules
- `2,4-5` - Combine both methods

### Non-Interactive Installation

Install specific modules without prompts:

```bash
./install.sh --modules=WORKSPACE,POMODORO,SYSTEM_METRICS
```

## Available Modules

### WORKSPACE
**Dynamic workspace indicators with app icons (1-6)**

Shows workspace numbers with Nerd Font icons for running applications. Features dynamic pill-shaped backgrounds and enhanced tooltips with window titles.

**Scripts:**
- `workspace-single.sh` - Individual workspace module
- `app-icons.sh` - Icon mapping for applications
- `workspaces.sh` - Original workspaces script

**Dependencies:** None

---

### POMODORO
**Pomodoro timer with collapsible controls (25/5/15 cycles)**

Full-featured Pomodoro timer with work sessions (25min), short breaks (5min), and long breaks (15min). Collapsible interface with play/pause and skip controls.

**Scripts:**
- `pomodoro-icon.sh` - Toggle icon
- `pomodoro.sh` - Timer display
- `pomodoro-play.sh` - Play/pause control
- `pomodoro-skip.sh` - Skip button

**Dependencies:** None

---

### SYSTEM_METRICS
**System monitoring (CPU, GPU, RAM) with rolling averages**

Unified collapsible system metrics monitor showing real-time CPU, GPU, and RAM utilization. Features 15-second rolling averages for smooth display and detailed tooltips showing top processes.

**Scripts:**
- `gpu-icon.sh` - Toggle icon
- `cpu.sh` - CPU usage with top 5 processes
- `gpu.sh` - GPU usage, temps, VRAM
- `ram.sh` - RAM usage with top 5 processes
- `power.sh` - GPU power consumption and cost (parked)

**Dependencies:** None

**Note:** Monitors AMD Radeon RX 9070 (card1) by default. You may need to adjust paths for different GPUs.

---

### SPOTIFY_LITE
**Spotify control with playback controls (lite version)**

Collapsible Spotify controller with song info, playback position, and media controls. Shows current song with italic titles and artist names.

**Scripts:**
- `spotify-icon.sh` - Toggle icon
- `spotify.sh` - Song info and position
- `spotify-prev.sh` - Previous track
- `spotify-play.sh` - Play/pause toggle
- `spotify-next.sh` - Next track

**Dependencies:** None

**Requirements:** `playerctl` package must be installed

---

## Updating Installations

### Update on the Same Machine

To update your current installation with the latest changes from the repository:

```bash
cd ~/Repos/GHyprland
git pull origin main
./install.sh --update
```

This will:
1. Show your currently installed modules
2. Ask if you want to update them or change the selection
3. Re-link all scripts to get the latest versions

### Update on a Different Machine

**From your laptop to your desktop:**

1. **On your laptop** (where you made changes):
   ```bash
   cd ~/Repos/GHyprland
   git add .
   git commit -m "Update Waybar modules"
   git push origin main
   ```

2. **On your desktop**:
   ```bash
   cd ~/Repos/GHyprland
   git pull origin main
   ./install.sh --update
   ```

The `--update` flag will:
- Read your previously installed modules from `~/.config/waybar/.installed_modules`
- Re-link all scripts to the latest versions
- Preserve your module selection
- Optionally let you add/remove modules

## How It Works

### Module Configuration

Modules are defined in `modules.conf`:

```ini
[MODULE_NAME]
description: Brief description of what this module does
scripts: space-separated list of script files
config_sections: config.jsonc sections this module requires
style_sections: style.css sections this module requires
dependencies: other modules this depends on (optional)
```

### Installation Tracking

When you install modules, the script saves your selection to:
```
~/.config/waybar/.installed_modules
```

This file is used during updates to remember which modules you have installed.

### Symlinks

All installations use symlinks, so:
- Changes in the repository are immediately reflected in your config
- No copying needed - just `git pull` to get updates
- Easy to track what's installed

## Adding New Modules

### For Future Development

When you create a new module (like Spotify Extended):

1. **Create your scripts** in `waybar/scripts/`
2. **Add the module definition** to `modules.conf`:
   ```ini
   [SPOTIFY_EXTENDED]
   description: Extended Spotify control with lyrics and album art
   scripts: spotify-ext-icon.sh spotify-ext.sh spotify-ext-lyrics.sh
   config_sections: custom/spotify-ext-icon custom/spotify-ext
   style_sections: spotify-ext-modules
   dependencies: SPOTIFY_LITE
   ```
3. **Run installation**:
   ```bash
   ./install.sh --modules=SPOTIFY_EXTENDED
   ```

The installer will automatically handle the new module.

## Command Reference

### Installation Commands

```bash
# Interactive installation (recommended for first install)
./install.sh

# Install everything
./install.sh --modules=WORKSPACE,POMODORO,SYSTEM_METRICS,SPOTIFY_LITE

# Install specific modules
./install.sh --modules=WORKSPACE,SYSTEM_METRICS

# Skip package installation (if already installed)
./install.sh --skip-packages

# Skip symlink creation (dry run for packages only)
./install.sh --skip-links
```

### Update Commands

```bash
# Update current installation
./install.sh --update

# Update with option to add/remove modules
./install.sh --update
# Then select option 2 in the menu
```

### Information Commands

```bash
# List all available modules
./install.sh --list-modules

# Show help
./install.sh --help
```

### Check Current Installation

```bash
# See which modules you have installed
cat ~/.config/waybar/.installed_modules
```

## Workflow Examples

### Fresh Installation on New Machine

```bash
# Clone the repository
git clone https://github.com/yourusername/GHyprland.git ~/Repos/GHyprland
cd ~/Repos/GHyprland

# Run interactive installation
./install.sh

# Select modules when prompted
# Example: Enter "1" for everything
```

### Add Module to Existing Installation

```bash
cd ~/Repos/GHyprland

# Update to get latest modules
git pull origin main

# Run update and add modules
./install.sh --update
# Select option 2: "Add/remove modules"
# Then select the new modules you want
```

### Update After Making Changes on Another Machine

**On laptop** (after making changes):
```bash
cd ~/Repos/GHyprland
git add waybar/scripts/cpu.sh  # Example: updated CPU script
git commit -m "Improve CPU monitoring tooltip"
git push origin main
```

**On desktop**:
```bash
cd ~/Repos/GHyprland
git pull origin main
./install.sh --update
# Select option 1: "Update these modules"
```

### Test New Module Without Affecting Main Setup

```bash
# Create a test branch
git checkout -b test-new-module

# Make your changes
# Add module to modules.conf
# Create scripts in waybar/scripts/

# Install just that module
./install.sh --modules=NEW_MODULE

# If it works, merge to main
git checkout main
git merge test-new-module
git push origin main
```

## Migration from Old Install

If you have an existing installation from the old `install.sh`:

1. **Check what you currently have**:
   ```bash
   ls ~/.config/waybar/scripts/
   ```

2. **Run the new installer**:
   ```bash
   ./install.sh
   ```

3. **Select "Everything" (option 1)** to install all modules

4. **The installer will**:
   - Back up your existing config files (`.backup.TIMESTAMP`)
   - Create new symlinks
   - Track your installation in `.installed_modules`

5. **Future updates** can now use:
   ```bash
   ./install.sh --update
   ```

## Troubleshooting

### Module Not Showing in Waybar

1. Check if scripts are linked:
   ```bash
   ls -la ~/.config/waybar/scripts/
   ```

2. Verify scripts are executable:
   ```bash
   chmod +x ~/.config/waybar/scripts/*.sh
   ```

3. Check Waybar config includes the module:
   ```bash
   grep "custom/modulename" ~/.config/waybar/config.jsonc
   ```

4. Restart Waybar:
   ```bash
   killall -SIGUSR2 waybar
   ```

### "No previous installation found" Error

This means you haven't installed using the new modular installer yet. Simply run:
```bash
./install.sh
```

Instead of:
```bash
./install.sh --update
```

### Scripts Not Updating After Git Pull

The symlinks should automatically reflect changes. If not:
```bash
# Re-link everything
./install.sh --update
```

### Module List Not Showing Correctly

Ensure `modules.conf` is properly formatted:
- Each module starts with `[MODULE_NAME]`
- Properties are on separate lines
- No extra spaces in property values

## Future Enhancements

Planned features for the modular system:

- [ ] Automatic dependency resolution
- [ ] Module version tracking
- [ ] Config section injection (automated config.jsonc editing)
- [ ] Style section injection (automated style.css editing)
- [ ] Module templates for easy creation
- [ ] Uninstall specific modules
- [ ] Module conflict detection
- [ ] Rollback capability
- [ ] Remote module registry

## Contributing

When contributing new modules:

1. Create scripts in `waybar/scripts/`
2. Add module definition to `modules.conf`
3. Test with `./install.sh --modules=YOUR_MODULE`
4. Document in this file
5. Submit pull request

## Support

If you encounter issues:

1. Check this documentation
2. Review `modules.conf` for module definitions
3. Verify scripts exist in `waybar/scripts/`
4. Check symlinks: `ls -la ~/.config/waybar/scripts/`
5. Open an issue on GitHub

---

**Last Updated:** 2025-11-09
**Version:** 2.0.0 (Modular)
