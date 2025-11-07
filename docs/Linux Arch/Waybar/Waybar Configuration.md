## Overview

Waybar is configured for Hyprland with an Omarchy theme. The configuration includes custom modules for GPU monitoring, CPU usage, RAM usage, and GPU electricity cost tracking. The setup uses **multi-monitor configuration** with different content on each display.

## Configuration Location

- **Config file**: `~/.config/waybar/config.jsonc`
- **Styles**: `~/.config/waybar/style.css`
- **Scripts**: `~/.config/waybar/scripts/`

## Multi-Monitor Setup

The configuration uses separate bar configurations for each monitor:

### DP-2 (Primary Monitor)
**Left:** Omarchy menu icon, Workspaces 1-6 (clickable, shows 3-letter app names for single-app workspaces)
**Center:** CPU usage | GPU usage | Power cost | RAM usage | Update indicator | Screen recording indicator
**Right:** Expandable system tray, Bluetooth, Network, Audio, Battery, Clock

### DP-1 (Secondary Monitor)
**Left:** Omarchy menu icon, Workspaces 1-6 (clickable, shows 3-letter app names for single-app workspaces)
**Center:** Pomodoro timer | Update indicator | Screen recording indicator
**Right:** Expandable system tray, Bluetooth, Network, Audio, Battery, Clock

**Note:** All 6 workspaces are displayed on both monitors for convenience. Workspaces are not tied to specific monitors.

## Custom Modules

### Workspace Modules (`custom/ws1` through `custom/ws6`)
- **Script**: `~/.config/waybar/scripts/workspace-single.sh`
- **Helper**: `~/.config/waybar/scripts/app-icons.sh` (icon mapping)
- **Update interval**: 1 second
- **Display**: Workspace number + application icons in brackets
- **Click action**: Switch to that workspace

Displays workspaces 1-6 with individual modules for each workspace. Shows Nerd Font icons for applications running on that workspace.

**Display format:**
- **Empty workspace**: `6` (just the number, no background)
- **Single app**: `3 ` (number + icon in pill-shaped background)
- **Multiple different apps**: `4  ` (number + each icon shown)
- **Multiple same app**: `1   ` (number + icon repeated for each instance)

**Display logic:**
- **Empty workspace**: Grey number only, no background
- **Occupied workspace**: Number + icons in slim pill-shaped background
- **Active workspace with apps**: Bold text with slightly brighter pill background
- **Active workspace without apps**: Circle shape instead of pill
- Icons repeat for multiple instances of the same app (no multipliers)
- Smooth 0.3s transitions when workspace state changes
- Dynamic Island style: pills expand/contract based on content, circles for empty active workspaces
- **Icon spacing**: Extra padding on right side (8px) to prevent icons from touching pill edge

**Features:**
- All workspaces visible on both monitors (not filtered by monitor)
- Individual click handlers for each workspace to switch to it
- Nerd Font icons for visual app identification
- Detects application names from Hyprland client class
- Handles Chrome web apps (extracts app name from class like `chrome-chatgpt.com__-Default`)
- Icons repeat for each instance (no multiplier notation like "x2")
- Real-time updates (1-second interval)
- CSS classes for styling: `active`, `active-empty`, `occupied`, `empty`, `visible`
- **Attempted feature (NOT WORKING)**: Colored border for workspaces visible on monitors
  - Script detects visible workspaces via `hyprctl monitors -j` and adds `visible` class
  - CSS attempts to apply cyan (#33ccff) border matching Hyprland theme
  - Currently not displaying - needs troubleshooting

**Supported application icons:**
- Chromium/Chrome:
- Firefox:
- ChatGPT/AI apps:
- VS Code:
- Obsidian:
- Terminal (Alacritty/Kitty):
- Spotify:
- Discord:
- File managers:
- And many more...

**Adding new icons:**
Edit `~/.config/waybar/scripts/app-icons.sh` to add mappings for additional applications. Use Nerd Font codepoints (e.g., `\uf120` for terminal icon).

**Styling customization:**
Edit `~/.config/waybar/style.css` to adjust the Dynamic Island appearance:
- **Pill shape**:
  - `border-radius: 10px;` - Adjust pill roundness (8px = less round, 15px = more round)
  - `padding: 1px 8px 1px 5px;` - Asymmetric padding (top, right, bottom, left) - more space on right for icons
  - `margin: 5px 3px;` - Spacing around pills (vertical, horizontal)
  - `background-color: rgba(255, 255, 255, 0.15);` - Occupied workspace opacity
  - `background-color: rgba(255, 255, 255, 0.25);` - Active workspace opacity (brighter)
- **Circle shape** (active-empty):
  - `border-radius: 50%;` - Makes it circular
  - `padding: 2px 6px;` - Slightly more padding for circle
  - `min-width: 16px; min-height: 16px;` - Ensures circular shape
- **General**:
  - `transition: all 0.3s ease;` - Animation speed for state changes
  - `border: 1px solid transparent;` - Transparent border (reserves space for potential colored border)

### CPU Module (`custom/cpu`)
- **Script**: `~/.config/waybar/scripts/cpu.sh`
- **Update interval**: 5 seconds
- **Rolling average**: 15 seconds (last 3 samples)
- **Display**: CPU usage percentage
- **Tooltip**: Top 5 CPU-consuming applications with usage percentages

Reads CPU usage from `/proc/stat` and calculates a rolling average over the past 15 seconds to smooth out spikes.

**Tooltip format:**
```
Top 5 CPU Usage:
▸ Chromium 6.4%
▸ Spotify 3.2%
▸ Claude 2.8%
▸ Hyprland 0.9%
▸ Dropbox 0.5%
```

**Features:**
- Aggregates CPU usage by application name (combines multiple processes)
- Handles Electron apps (detects `/proc/self/exe` and extracts real app name from `--user-data-dir` or `.asar` paths)
- Capitalizes application names
- Uses triangle bullets (▸) for better readability
- Shows descending order by CPU usage

### GPU Module (`custom/gpu`)
- **Script**: `~/.config/waybar/scripts/gpu.sh`
- **Update interval**: 5 seconds
- **Rolling average**: 15 seconds (last 3 samples)
- **Display**: GPU usage percentage
- **Tooltip**:
  - GPU usage percentage
  - Edge temperature
  - Junction temperature
  - Memory temperature
  - VRAM usage (used/total in GB and percentage)

Monitors the AMD Radeon RX 9070 (dedicated GPU on card1):
- GPU usage: `/sys/class/drm/card1/device/gpu_busy_percent`
- Temperatures: `/sys/class/drm/card1/device/hwmon/hwmon2/temp{1,2,3}_input`
  - temp1: Edge temperature
  - temp2: Junction temperature
  - temp3: Memory temperature
- VRAM: `/sys/class/drm/card1/device/mem_info_vram_{used,total}`

### RAM Module (`custom/ram`)
- **Script**: `~/.config/waybar/scripts/ram.sh`
- **Update interval**: 5 seconds
- **Rolling average**: 15 seconds (last 3 samples)
- **Display**: RAM usage percentage
- **Tooltip**: Overall RAM usage summary + Top 5 memory-consuming applications

Reads memory information from `/proc/meminfo` and calculates usage as a rolling average.

**Tooltip format:**
```
RAM: 6.0GB / 60.4GB (10%)

Top 5 Memory Usage:
▸ Chromium 3.62GB (6.0%)
▸ Spotify 1.39GB (2.3%)
▸ Dropbox 0.42GB (0.7%)
▸ Electron 0.36GB (0.6%)
▸ Obsidian 0.30GB (0.5%)
```

**Features:**
- Shows total RAM usage (used/total in GB and percentage)
- Lists top 5 memory-consuming applications with both GB and percentage
- Aggregates memory usage by application name (combines multiple processes)
- Handles Electron apps (detects `/proc/self/exe` and extracts real app name from `--user-data-dir` or `.asar` paths)
- Capitalizes application names
- Uses triangle bullets (▸) for better readability
- Shows descending order by memory usage

### Power/Cost Module (`custom/power`)
- **Script**: `~/.config/waybar/scripts/power.sh`
- **Update interval**: 20 seconds
- **Rolling average**: 60 seconds (last 3 samples @ 20s interval)
- **Display**: GPU electricity cost per hour in euros
- **Electricity rate**: €0.35/kWh
- **Tooltip**:
  - GPU power consumption in watts
  - Cost per hour
  - Cost per day (extrapolated)
  - Electricity rate

Reads GPU power from `/sys/class/drm/card1/device/hwmon/hwmon2/power1_average` (in microwatts) and calculates:
- Average power over 60 seconds
- Cost per hour = (Power in kW) × (€0.35/kWh)

**Note**: Currently only tracks GPU power consumption. CPU power tracking via RAPL requires additional permissions (see Troubleshooting section).

### Pomodoro Timer (`custom/pomodoro` + `custom/pomodoro-skip`)
- **Scripts**: `~/.config/waybar/scripts/pomodoro.sh` and `~/.config/waybar/scripts/pomodoro-skip.sh`
- **Update interval**: 1 second
- **Display**: Timer with phase icon and countdown
- **Location**: DP-1 (Secondary Monitor) center

A full-featured Pomodoro timer using the classic technique:
- 25-minute work sessions
- 5-minute short breaks
- 15-minute long breaks (after every 4 pomodoros)

**Display format:**
- Running: `🍅 24:32` (work) / `🧋 04:15` (short break) / `🥨 14:20` (long break)
- Paused: `⏸ 24:32 ▶▶` (skip button appears when paused)

**Icons:**
- 🍅 - Work session (25 min)
- 🧋 - Short break (5 min)
- 🥨 - Long break (15 min)
- ⏸ - Timer paused
- ▶▶ - Skip button (appears only when paused)

**Controls:**
- **Left click timer**: Start/Pause
- **Right click timer**: Reset timer and counter
- **Left click skip button**: Skip to next phase and auto-start

**Notifications:**
- Timer started/paused/reset
- 15 minutes remaining (work sessions only)
- 5 minutes remaining (all phases)
- Phase complete (work/break finished)

**Features:**
- Tracks completed pomodoros count
- Automatically switches between work and breaks
- State persists across script runs (stored in `/tmp`)
- Notifications for all state changes and time warnings
- Skip button only visible when paused

**Tooltip shows:**
- Current phase (Work Session / Short Break / Long Break)
- Status (Running / Stopped)
- Time remaining
- Completed pomodoros count
- Available controls

**Configuration:**
Edit `~/.config/waybar/scripts/pomodoro.sh` to customize:
```bash
WORK_TIME=1500        # 25 minutes (in seconds)
SHORT_BREAK=300       # 5 minutes
LONG_BREAK=900        # 15 minutes
POMODOROS_UNTIL_LONG=4
```

## GPU Hardware

- **card0**: AMD Granite Ridge integrated GPU (iGPU)
- **card1**: AMD Radeon RX 9070 dedicated GPU (monitored by custom modules)

## Key Settings

```jsonc
{
  "reload_style_on_change": true,
  "layer": "top",
  "position": "top",
  "height": 26
}
```

## Performance Impact

The custom modules have minimal performance impact:
- **CPU usage**: ~0.01-0.05% average
- **RAM**: ~5-10MB total for history files
- **Disk**: State files in `/tmp` (few KB total)
- **Update frequency**: Scripts run for microseconds every 1-20 seconds

All system monitoring data is read from sysfs (kernel interface) - no disk I/O, extremely fast. The Pomodoro timer uses simple file-based state management in `/tmp` with negligible overhead.

## Reloading Waybar

To reload configuration changes:
```bash
killall -SIGUSR2 waybar
```

To restart waybar completely:
```bash
killall waybar && waybar &
```

## Known Issues

### Workspace border for visible monitors not displaying

**Issue**: Attempting to add a colored cyan border (matching Hyprland's active window border) to workspaces that are currently visible on either monitor. The border should help identify which workspaces are being displayed.

**Current status**:
- Script successfully detects visible workspaces using `hyprctl monitors -j`
- Script adds `visible` class to the JSON output (verified with test: workspace shows `"class":"active visible"`)
- CSS rules are defined for `.occupied.visible`, `.active.visible`, and `.active-empty.visible`
- Border color set to `#33ccff` (cyan from Hyprland theme at `~/.config/omarchy/current/theme/hyprland.conf`)
- **Problem**: Border is not displaying in waybar despite correct classes being applied

**What was tried**:
1. Initial attempt with `border-image: linear-gradient(...)` - broke pill shapes (gradient doesn't work with border-radius)
2. Changed to solid `border: 1px solid #33ccff` with `.visible` selector
3. Added transparent borders to all states and used `.occupied.visible` combination selectors
4. Waybar restarted multiple times - no errors in output

**Files modified**:
- `/home/bjorn/.config/waybar/scripts/workspace-single.sh` - lines 16, 20, 90-93 (monitor detection and visible class)
- `/home/bjorn/.config/waybar/style.css` - lines 73, 100, 128 (transparent borders) and lines 77-84, 104-111, 132-139 (visible borders)

**Next steps to try**:
- Verify CSS selector specificity isn't being overridden
- Test with `!important` flag
- Check if waybar is actually applying the classes with browser dev tools or waybar debug mode
- Consider using a different approach (box-shadow instead of border?)
- Simplify to test with just background-color change on .visible class first

## Troubleshooting

### Custom modules not showing

Custom modules must be prefixed with `custom/` in both:
1. The module list (e.g., `"modules-center"`)
2. The module definition

### GPU module shows "N/A"

Check if the GPU sysfs files are accessible:
```bash
cat /sys/class/drm/card1/device/gpu_busy_percent
cat /sys/class/drm/card1/device/mem_info_vram_used
```

### JSON parsing errors

Ensure scripts output valid JSON. Test with:
```bash
~/.config/waybar/scripts/gpu.sh | jq .
~/.config/waybar/scripts/cpu.sh | jq .
~/.config/waybar/scripts/ram.sh | jq .
~/.config/waybar/scripts/power.sh | jq .
~/.config/waybar/scripts/pomodoro.sh | jq .
~/.config/waybar/scripts/pomodoro-skip.sh | jq .
```

Newlines in tooltips must be escaped as `\\n` in bash strings.

### CPU Power Monitoring (RAPL)

The power module can include CPU power consumption, but it requires read access to RAPL energy counters.

**Permanent fix** - Create `/etc/udev/rules.d/99-rapl.rules`:
```
# Allow users to read Intel RAPL energy counters
SUBSYSTEM=="powercap", KERNEL=="intel-rapl:*", RUN+="/bin/chmod -R a+r /sys/devices/virtual/powercap/intel-rapl"
```

Then reload:
```bash
sudo udevadm control --reload-rules
sudo udevadm trigger
```

**Temporary fix** (resets on reboot):
```bash
sudo chmod -R a+r /sys/devices/virtual/powercap/intel-rapl
```

### Different content per monitor

The config uses an array of bar configurations with the `"output"` property to specify which monitor each bar appears on. Module definitions must be included in each bar configuration separately.

### Pomodoro timer issues

**Skip button always showing or not appearing:**
- The skip button checks `/tmp/waybar_pomodoro_state` to determine visibility
- Ensure the file exists and contains either `running` or `stopped`
- If stuck, reset: `echo "stopped" > /tmp/waybar_pomodoro_state`

**Decimal intervals not working:**
- Waybar only accepts integer intervals (1, 2, 3, etc.)
- Decimal values like 0.5 or 0.1 will cause the module to malfunction
- Use whole numbers only

**Notifications not appearing:**
- Ensure `notify-send` is installed and working
- Test: `notify-send "Test" "This is a test notification"`
- Check your notification daemon is running

**Timer state persists after restart:**
- Timer state is stored in `/tmp/waybar_pomodoro_*` files
- To completely reset: `rm /tmp/waybar_pomodoro_*`
- Files are automatically cleared on system reboot

## Customization

### Changing electricity rate

Edit `~/.config/waybar/scripts/power.sh` and modify:
```bash
COST_PER_KWH=0.35  # Change to your rate
```

### Adjusting update intervals

Modify the `"interval"` value in each module definition:
- CPU, GPU, RAM: Currently 5 seconds (good balance)
- Power/Cost: Currently 20 seconds (calculates 60-second average)
- Pomodoro: 1 second (timer countdown and skip button visibility)

**Note**: Waybar's `interval` parameter only accepts integers (whole numbers), not decimals. Values like `0.5` or `0.1` will not work.

### Modifying rolling average window

Edit the script and change how many readings are kept:
- Currently: 3 readings
- To increase window: Change `if [ ${#history[@]} -gt 3 ]` to a higher number
- Adjust interval accordingly to match desired time window

### Changing bullet style in tooltips

The CPU and RAM modules use triangle bullets (▸) in their tooltips. To change the bullet style, edit the respective script files and replace `▸` with your preferred character:

**Popular bullet options:**
- Classic bullet: `•`
- Arrow: `→`
- Chevron: `›`
- Double chevron: `»`
- Triangle (current): `▸`
- Square: `▪`
- Diamond: `◆`

**Example:** In `cpu.sh` or `ram.sh`, find the line:
```bash
printf "▸ %s %s%%\\n", $1, $2
```
And replace `▸` with your preferred bullet character.

### Changing Pomodoro timer icons

The Pomodoro timer uses custom emoji icons for different phases. To change them, edit `~/.config/waybar/scripts/pomodoro.sh`:

**Current icons:**
- 🍅 Work session
- 🧋 Short break (bubble tea)
- 🥨 Long break (pretzel)
- ⏸ Paused

Find the icon section (around line 132-162) and replace emojis:
```bash
case "$phase" in
    work)
        icon="🍅"  # Change work icon here
        ;;
    short_break)
        icon="🧋"  # Change short break icon here
        ;;
    long_break)
        icon="🥨"  # Change long break icon here
        ;;
esac
```

To change the skip button icon, edit `~/.config/waybar/scripts/pomodoro-skip.sh` line 23:
```bash
echo "{\"text\":\" ▶▶\",\"tooltip\":\"Skip to next phase\",\"class\":\"paused\"}"
```
Replace `▶▶` with your preferred icon (e.g., `⏭`, `→`, `»`, etc.)

## Notes

- The configuration uses JSONC format (JSON with comments)
- Waybar automatically reloads styles on change
- Custom scripts must have executable permissions (`chmod +x`)
- The Omarchy theme integrates with the Hyprland workflow
- Separators (`|`) between center modules improve visual distinction
- History and state files are stored in `/tmp` and persist across script runs but reset on reboot
- The Pomodoro timer uses two separate modules (`custom/pomodoro` and `custom/pomodoro-skip`) to enable independent click handlers - this is a workaround for Waybar's one-click-area-per-module limitation
