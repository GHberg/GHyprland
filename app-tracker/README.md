# Application Usage Tracker

A lightweight application usage tracker for Hyprland that monitors active and passive time for all running applications.

## Features

- **Active Time Tracking**: Tracks time when you're actively focused on an application
- **Passive Time Tracking**: Tracks time when an application is running in the background
- **Total Time**: Active + Passive time for complete usage statistics
- **Smart Lock Screen Handling**: Automatically pauses tracking when screen is locked
- **Minimal Overhead**: Simple SQLite database, ~1% CPU usage
- **CLI Interface**: No complex web UI, just simple command-line queries

## What Gets Tracked

**Active Time**: When you're focused on the application (keyboard/mouse focus)
- Example: Coding in your editor, typing in terminal, browsing in browser

**Passive Time**: When the application is running but not focused
- Example: Spotify playing music while you work, browser open on another workspace

**Not Tracked**:
- Window titles or content
- Browser tabs or URLs
- Song names or media details
- Screensaver/lock screen time

## Installation

1. **Copy scripts to local bin:**
   ```bash
   cp app-tracker ~/.local/bin/app-tracker
   cp app-stats ~/.local/bin/app-stats
   chmod +x ~/.local/bin/app-tracker
   chmod +x ~/.local/bin/app-stats
   ```

2. **Already configured in autostart:**
   The tracker is already configured in `hypr/autostart.conf` and will start automatically on boot.

3. **Verify it's running:**
   ```bash
   ps aux | grep app-tracker
   ```

## Usage

### View Today's Statistics

```bash
app-stats today
```

Output:
```
App                  Active     Passive    Total      Sessions
-----------------------------------------------------------------
Alacritty            2h 27m     7m         2h 34m     5
chromium             2m         2h 32m     2h 34m     3
Spotify              0s         2h 34m     2h 34m     1
-----------------------------------------------------------------
TOTAL                2h 29m     5h 13m     7h 42m
```

### View Recent Sessions

```bash
app-stats recent 10    # Last 10 sessions
app-stats recent 20    # Last 20 sessions
```

Output:
```
Time         App                  Active     Passive    Total
-----------------------------------------------------------------
15:30:15     Alacritty            10m        2m         12m
15:20:30     chromium             5m         15m        20m
```

### View All-Time Statistics

```bash
app-stats all
```

Shows cumulative statistics across all tracked sessions.

## Database Location

Data is stored in: `~/.local/share/app-tracker/usage.db`

- SQLite database format
- Simple schema with active/passive time columns
- Can be queried directly with `sqlite3` if needed

## How It Works

1. **Monitors all running applications** via `hyprctl clients -j`
2. **Detects active window** via `hyprctl activewindow -j`
3. **Every second:**
   - Adds 1 second to active_time for the focused app
   - Adds 1 second to passive_time for all other running apps
4. **Lock screen detection:**
   - Detects screensaver/hyprlock/swaylock
   - Closes all sessions and pauses tracking
   - Resumes with fresh sessions when unlocked

## Architecture

### app-tracker
Main tracking daemon that runs in the background:
- Polls Hyprland every 1 second
- Maintains sessions for all running applications
- Tracks active vs passive time separately
- Handles lock screen pause/resume

### app-stats
Query tool for viewing statistics:
- Reads from SQLite database
- Filters out screensaver entries
- Supports today/recent/all-time views
- Formats durations as human-readable (5m, 2h 30m, etc.)

### Database Schema

```sql
CREATE TABLE app_sessions_v2 (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    app_name TEXT NOT NULL,
    started_at TEXT NOT NULL,
    ended_at TEXT,
    active_seconds INTEGER DEFAULT 0,
    passive_seconds INTEGER DEFAULT 0
);
```

## Example Use Cases

**Track work focus:**
```bash
app-stats today
# See which apps you actually focused on vs just had open
```

**Analyze productivity patterns:**
```bash
app-stats all
# Identify which apps consume most of your active time
```

**Quick check recent activity:**
```bash
app-stats recent 5
# See what you've been working on in the last few sessions
```

## Privacy

- All data stored locally in `~/.local/share/app-tracker/`
- No network connections or external services
- No window titles, URLs, or content tracked
- Only application names (class) and timestamps

## Troubleshooting

**Tracker not running:**
```bash
# Start manually
app-tracker &

# Check logs (if running in foreground)
app-tracker
```

**No data showing:**
```bash
# Check if database exists
ls -la ~/.local/share/app-tracker/

# Check for active sessions
sqlite3 ~/.local/share/app-tracker/usage.db \
  "SELECT * FROM app_sessions_v2 WHERE ended_at IS NULL;"
```

**Reset all data:**
```bash
# WARNING: This deletes all tracking history
rm -rf ~/.local/share/app-tracker/
# Tracker will recreate database on next start
```

## Customization

### Changing Poll Interval

Edit `app-tracker` and change:
```python
POLL_INTERVAL = 1.0  # Change to 2.0 for every 2 seconds, etc.
```

### Adding Lock Screen Detection

The tracker detects these lock screens by default:
- `Screensaver`
- `hyprlock`
- `swaylock`

To add more, edit `app-tracker`:
```python
is_screensaver = active_app and active_app.lower() in [
    'screensaver', 'hyprlock', 'swaylock', 'your-lock-screen'
]
```

## Future Enhancements

Potential additions (not yet implemented):
- [ ] Weekly/monthly summary reports
- [ ] Export to CSV/JSON
- [ ] Simple web dashboard
- [ ] Tagging/categorizing applications
- [ ] Goal tracking (e.g., "code at least 4 hours today")
- [ ] Integration with waybar module

## See Also

- [Workspace Management Documentation](../waybar/WORKSPACE.md)
- [Hyprland Configuration](../hypr/)
