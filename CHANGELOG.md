# Changelog

## [2.0.0] - 2025-11-09

### Added - Modular Installation System

**Major Change:** Complete overhaul of the installation system to support modular, selective installation of Waybar components.

#### New Features

- **Modular Installation**: Install only the Waybar modules you need
  - WORKSPACE - Dynamic workspace indicators with app icons
  - POMODORO - Pomodoro timer with collapsible controls
  - SYSTEM_METRICS - CPU/GPU/RAM monitoring with rolling averages
  - SPOTIFY_LITE - Spotify control with playback controls

- **Interactive Module Selection**: User-friendly prompts for choosing modules
  - Install everything with option 1
  - Select specific modules (e.g., `2,4,5`)
  - Select ranges of modules (e.g., `2-5`)
  - Combine both methods (e.g., `2,4-5`)

- **Update System**: Simple update mechanism for existing installations
  - `./install.sh --update` to update existing modules
  - Option to add/remove modules during update
  - Preserves module selection across updates

- **Non-Interactive Mode**: Command-line installation for automation
  - `./install.sh --modules=WORKSPACE,POMODORO`
  - `./install.sh --list-modules`

#### New Files

- `modules.conf` - Module definitions and metadata
- `MODULAR_INSTALL.md` - Comprehensive documentation for the modular system
- `CHANGELOG.md` - This file

#### Changed

- `install.sh` - Complete rewrite to support modular installation
  - Added argument parsing
  - Added module configuration system
  - Added installation tracking
  - Added update functionality
  - Improved user feedback with colored output

#### Benefits

1. **Flexibility**: Install only what you need on each machine
2. **Maintainability**: Easy to add new modules without changing install script
3. **Updates**: Simple git pull + update workflow
4. **Multi-machine**: Easy synchronization across laptop/desktop
5. **Testing**: Install new modules without affecting existing setup

#### Migration from v1.0

Existing installations can migrate by simply running:
```bash
./install.sh
```

Select "Everything" (option 1) to install all modules. Future updates can use:
```bash
./install.sh --update
```

---

## [1.0.0] - 2025-11-07

### Initial Release

- Basic installation script for Hyprland + Waybar
- All-or-nothing installation approach
- Workspace indicators with app icons
- Pomodoro timer
- System metrics monitoring (CPU, GPU, RAM)
- Spotify control
- Hyprsunset configuration
