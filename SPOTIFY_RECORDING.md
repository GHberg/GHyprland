# Spotify Recording System

Automatic bit-perfect Spotify recording integrated with Waybar controls.

## Overview

This system automatically captures each Spotify track to separate WAV files, organized by Artist/Album, maintaining **bit-perfect 44.1 kHz, 32-bit float quality**.

**Key Feature:** Records **ONLY Spotify's audio stream** - you can use other applications, watch videos, get notifications, etc. without affecting the recording.

## Quality Guarantee

**Zero Quality Loss - Bit-Perfect Digital Capture**

- **Clock:** Forced to 44.1 kHz (matches Spotify output exactly)
- **Format:** 32-bit float WAV (maximum headroom, no clipping)
- **Channels:** Stereo (2 channels)
- **Source:** Spotify's audio stream only (isolated from other system sounds)
- **Path:** Direct from PipeWire application stream (before DAC)
- **Processing:** NONE - no resampling, no normalization, no EQ

### Audio Signal Path

```
Spotify (Ogg Vorbis 44.1 kHz)
    ↓
PipeWire Application Stream (44.1 kHz) ← ISOLATED from other apps
    ↓
pw-record --target spotify (44.1 kHz, f32)
    ↓
WAV file (bit-perfect)

Other system sounds → PipeWire → Your speakers (NOT recorded)
```

## Features

### Isolated Recording (ONLY Spotify)

- **Application-Specific:** Records ONLY Spotify's audio stream
- **Dynamic Node Detection:** Automatically finds Spotify in PipeWire on each recording
- **No System Interference:** Use other apps freely without affecting the recording
- **Safe Fallback:** If Spotify node not found, falls back to monitor recording (logs warning)
- **Quality Preserved:** Isolation doesn't affect bit-perfect quality

**What this means for you:**
- Play YouTube videos while recording Spotify ✅
- Get notifications without ruining recordings ✅
- Use Discord/Zoom without audio bleed ✅
- System sounds won't contaminate your recordings ✅

### Automatic Recording

- **Track Detection:** Automatically detects new tracks via playerctl metadata
- **Separate Files:** Each track saved to individual WAV file
- **Smart Organization:** Files organized by Album Artist/Album/Track
- **Album Artist Logic:** Uses `xesam:albumArtist` to keep all tracks from same album together (even with featured artists)
- **Duplicate Handling:** Increments filename if track exists
- **Metadata Extraction:** Uses xesam:albumArtist (folder), xesam:album, xesam:title, xesam:trackNumber

### File Organization

```
~/Recordings/Spotify/
├── Album Artist Name/              # Uses xesam:albumArtist (main artist)
│   ├── Album Name/
│   │   ├── 01 - Track Title.wav
│   │   ├── 02 - Track feat. Other Artist.wav  # Still in same folder!
│   │   └── 03 - Track Title.wav
│   └── Singles/
│       └── Track Title.wav
└── Unknown Artist/
    └── Unknown Album/
        └── Track Title.wav
```

**Why Album Artist?**
- **"Main Artist"** has an album with 10 tracks
- Track 5 features another artist: **"Main Artist feat. Guest"**
- Using `albumArtist` keeps all 10 tracks in: `Main Artist/Album Name/`
- Using `artist` would split track 5 into: `Main Artist feat. Guest/Album Name/`

This keeps your library organized by actual album releases, not individual track credits.

### Waybar Integration

Three new modules added to Spotify control:

1. **Recording Indicator (⏺):**
   - Red pulsing dot when recording active
   - Orange when paused
   - Hidden when recording disabled

2. **Recording Toggle (REC):**
   - Click to enable/disable recording
   - Red bold text when enabled
   - Gray text when disabled

3. **Enhanced Tooltip:**
   - Shows recording status in Spotify info tooltip
   - Displays quality settings when recording

## Prerequisites

### Spotify Settings (CRITICAL)

Open Spotify → Settings and configure:

**Must Enable:**
- ✅ Streaming quality: **Very High**
- ✅ Download quality: **Very High**
- ✅ Volume slider: **100%**

**Must Disable:**
- ❌ Volume normalization
- ❌ Crossfade
- ❌ Equalizer
- ❌ Mono audio

These settings ensure Spotify outputs a clean, unaltered 44.1 kHz stream.

### System Dependencies

Already installed in GHyprland:
- PipeWire (audio server)
- playerctl (media control)
- pw-record (recording tool)
- notify-send (notifications)

## Usage

### Basic Workflow

1. **Enable Recording:**
   - Click the "REC" button in Waybar
   - System clock automatically set to 44.1 kHz
   - Recording daemon starts
   - Notification confirms activation

2. **Play Spotify:**
   - Start playing any track
   - If track is already playing (>3 seconds in), it will be skipped
   - Recording begins only when next track starts from the beginning
   - Red ⏺ indicator appears when recording is active

3. **Track Changes:**
   - Daemon detects new track
   - Previous recording stopped and saved
   - New recording starts automatically (only if track is at the beginning)

4. **Disable Recording:**
   - Click the "REC" button again
   - Daemon stops
   - PipeWire restarted (restores default clock)
   - Notification confirms deactivation

### Important: Full Song Recording

The daemon **only records songs from the beginning**. If you enable recording while a song is already playing (more than 3 seconds in), that song will be **skipped** and recording will start with the next track. This ensures you always capture complete songs, not partial recordings.

### Visual Indicators

**Recording Toggle Button:**
- `REC` (gray) = Recording disabled
- `REC` (red, bold) = Recording enabled

**Recording Indicator:**
- ⏺ (red, pulsing) = Recording active
- ⏺ (orange) = Recording paused
- (hidden) = Recording disabled

**Spotify Info Tooltip:**
- Shows "⏺ Recording: ENABLED" when active
- Shows "Quality: 44.1 kHz, 32-bit float"

## Technical Details

### Scripts

**spotify-record-daemon.sh**
- Background daemon monitoring playerctl metadata
- Detects track changes via mpris:trackid
- Manages pw-record processes
- Handles metadata extraction and file organization
- Logs activity to `/tmp/waybar-spotify-record-daemon.log`

**spotify-record-toggle.sh**
- Enables/disables recording
- Manages system clock (44.1 kHz)
- Starts/stops daemon
- Restarts PipeWire on disable
- Sends notifications

**spotify-record-icon.sh**
- Shows recording status indicator
- Updates based on playback status
- Provides visual feedback

### State Files

- `/tmp/waybar-spotify-recording-enabled` - "1" or "0"
- `/tmp/waybar-spotify-record-daemon-pid` - Daemon process PID
- `/tmp/waybar-spotify-record-pw-pid` - Current pw-record PID
- `/tmp/waybar-spotify-last-trackid` - Prevents duplicate recordings
- `/tmp/waybar-spotify-record-daemon.log` - Activity log

### Recording Command

The exact pw-record command used (with isolation):

```bash
# Find Spotify's PipeWire node dynamically
spotify_node=$(pw-cli list-objects | grep -A 3 "application.name = \"spotify\"" | grep "node.name" | awk -F'"' '{print $2}')

# Record ONLY from Spotify's audio stream
pw-record \
  --target "$spotify_node" \
  --media-category Capture \
  --rate 44100 \
  --format f32 \
  --channels 2 \
  "$filepath"
```

**How isolation works:**
- `--target "$spotify_node"` tells pw-record to capture ONLY Spotify's output
- The node name is detected dynamically (changes on reboot/restart)
- If detection fails, falls back to monitor recording (all audio) with a warning in the log

**No modifications, no post-processing, bit-perfect.**

## Edge Cases & Behavior

### Enable Recording Mid-Song
- If you enable recording while a track is already playing (>3 seconds in), that track will be **skipped**
- Recording will automatically start with the **next track** that begins from 0:00
- This ensures you only capture complete songs

### Track Skipping
- If you skip track before it finishes, recording stops immediately
- File is saved as-is (partial track)
- **Note:** This is different from enabling mid-song - manual skipping still saves the partial recording

### Pause/Resume
- Recording continues during pause (captures silence)
- Indicator turns orange when paused
- To avoid recording silence, disable recording before pausing

### Spotify Restart
- Daemon waits for Spotify reconnection
- Recording resumes automatically when Spotify starts
- Will skip currently playing track if it's not at the beginning

### Duplicate Tracks
- Compares track ID to avoid duplicate recordings on metadata refresh
- If same track file exists, appends (2), (3), etc.

### Missing Metadata
- If `albumArtist` missing, falls back to `artist` (track artist)
- If both missing, uses "Unknown Artist"
- If album missing, uses "Singles"
- Track number defaults to "00"

### Long Filenames
- Sanitizes invalid characters: `/\:*?"<>|` → `_`
- Truncates to 200 characters if needed
- Always preserves `.wav` extension

## Troubleshooting

### Recording Not Starting

1. Check Spotify is playing:
   ```bash
   playerctl -p spotify status
   ```

2. Check daemon is running:
   ```bash
   ps aux | grep spotify-record-daemon
   ```

3. Check daemon log:
   ```bash
   tail -f /tmp/waybar-spotify-record-daemon.log
   ```

4. Check if Spotify node was found:
   ```bash
   grep "Found Spotify node" /tmp/waybar-spotify-record-daemon.log
   ```

   If you see "WARNING: Could not find Spotify node", it's recording from the monitor (all audio).

### Other Sounds Being Recorded

If you hear non-Spotify sounds in your recordings:

1. Check the daemon log for warnings:
   ```bash
   grep "WARNING" /tmp/waybar-spotify-record-daemon.log
   ```

2. If you see "Could not find Spotify node", the daemon fell back to monitor recording.

3. Ensure Spotify is actively playing when you start recording (not paused).

4. Restart Spotify and re-enable recording to re-detect the node.

### Empty or Silent Recordings

1. Verify Spotify settings (see Prerequisites)
2. Check volume is 100% in Spotify
3. Ensure volume normalization is OFF

### Clock Not Set

Recording toggle automatically sets clock. Verify with:
```bash
pw-metadata -n settings | grep clock.force-rate
```

Should show: `clock.force-rate = '44100'`

### PipeWire Issues

If audio stops working after recording:
```bash
systemctl --user restart pipewire
```

This is done automatically when disabling recording.

## Quality Verification

### Check Recording Format

```bash
file ~/Recordings/Spotify/Artist/Album/Track.wav
```

Should show:
- RIFF (little-endian) data
- WAVE audio
- stereo 44100 Hz

### Verify Bit Depth

```bash
soxi ~/Recordings/Spotify/Artist/Album/Track.wav
```

Should show:
- Channels: 2
- Sample Rate: 44100
- Precision: 32-bit
- Sample Encoding: 32-bit Floating Point PCM

## Post-Recording (Optional)

### Convert to FLAC (Lossless Compression)

```bash
for file in ~/Recordings/Spotify/*/*/*\.wav; do
  flac --best "$file" && rm "$file"
done
```

**Note:** Converting lossy Spotify audio to FLAC doesn't improve quality, but reduces file size.

### Trim Silence (Advanced)

Only if you want to remove silence at track boundaries:

```bash
ffmpeg -i input.wav -af silenceremove=1:0:-50dB output.wav
```

**Warning:** This requires decoding/re-encoding. Only do this if necessary.

## System Clock Management

### When Recording Enabled
```bash
pw-metadata -n settings 0 clock.force-rate 44100
```

Forces system to 44.1 kHz (matches Spotify, prevents resampling).

### When Recording Disabled
```bash
systemctl --user restart pipewire
```

Restores default clock behavior (adaptive).

## Uninstall/Disable

### Temporary Disable
- Simply don't click the REC button
- Scripts remain inactive

### Remove from Waybar

Edit `~/.config/waybar/config.jsonc`:
1. Remove from modules-center:
   - `"custom/spotify-record-icon"`
   - `"custom/spotify-record-toggle"`

2. Restart Waybar:
   ```bash
   pkill waybar && waybar &
   ```

### Complete Removal

```bash
rm ~/.config/waybar/scripts/spotify-record-*.sh
```

## Integration with App Tracker

The recording daemon logs activity but doesn't integrate with app-tracker. If you want to track recording time, you could extend app-tracker to monitor the daemon PID.

## Credits

**Recording Methodology:** Based on ChatGPT-optimized PipeWire capture
**Implementation:** Claude Code (Anthropic)
**Integration:** GHyprland modular Waybar system

---

**Remember:** Spotify audio is lossy (Ogg Vorbis). This system captures it bit-perfectly, but cannot improve the inherent quality of the source. This is the maximum possible quality for Spotify recordings on Linux.
