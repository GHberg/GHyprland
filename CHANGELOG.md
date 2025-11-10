# Changelog

## [2.1.0] - 2025-11-10

### Added - Dynamic Workspace Management

**Major Feature:** Enhanced workspace system with support for up to 12 workspaces and intelligent auto-show/hide behavior.

#### New Features

- **Extended Workspace Support (1-12)**
  - Workspaces 1-4: Core workspaces, always visible in waybar
  - Workspaces 5-12: Dynamic workspaces that appear only when occupied
  - Seamless integration with existing Dynamic Island styling

- **"+" Button for Workspace Creation**
  - New `workspace-add.sh` script
  - Click to create and switch to the next sequential workspace
  - Automatically finds highest workspace ID and creates the next one
  - Subtle pill-shaped styling with hover effect

- **Intelligent Auto-Hide Behavior**
  - Workspaces 5-12 automatically appear when you open applications in them
  - Empty workspaces 5+ automatically hide when you switch away
  - Hyprland's native workspace cleanup works seamlessly
  - No manual cleanup required

- **Enhanced workspace-single.sh Script**
  - Modified to handle 1-12 workspaces
  - Logic to hide empty workspaces >= 5
  - Returns "hidden" CSS class for empty dynamic workspaces
  - Same icon display and tooltip behavior for all workspaces

#### New Files

- `waybar/scripts/workspace-add.sh` - Script for "+" button functionality

#### Changed

- `waybar/config.jsonc` - Added ws7-ws12 modules and workspace-add module
- `waybar/style.css` - Added CSS styling for ws7-ws12 and hiding rules for empty dynamic workspaces (5-12)
- `waybar/scripts/workspace-single.sh` - Added logic to hide workspaces 5+ when empty

#### Benefits

1. **Flexibility**: Use as many or as few workspaces as you need
2. **Clean UI**: Waybar only shows workspaces that are in use
3. **On-demand Creation**: Easily create new workspaces without keybindings
4. **Automatic Cleanup**: Empty workspaces disappear automatically
5. **Scalability**: Support for up to 12 workspaces with room to expand

#### User Experience

**Creating a new workspace:**
1. Click the "+" button after workspace 4
2. Automatically switches to workspace 5 (or next available)
3. Open an application
4. Workspace 5 appears in waybar with app icon

**Automatic cleanup:**
1. Create workspace 5 with "+" button
2. Don't open anything
3. Switch back to another workspace
4. Workspace 5 automatically disappears from waybar
5. Hyprland removes the empty workspace

---

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
