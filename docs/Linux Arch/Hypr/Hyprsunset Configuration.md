## Overview

Hyprsunset is a blue light filter for Hyprland that adjusts screen color temperature throughout the day. The configuration implements a **research-based** gradual transition system that mimics natural daylight cycles (2700K sunrise → 6500K midday → 2500K sunset) to support healthy circadian rhythms and optimize sleep quality.

## Configuration Location

- **Config file**: `~/.config/hypr/hyprsunset.conf`

## Daily Schedule

The configuration creates a complete day/night cycle with two main transition periods:

### Morning Transition (07:00 - 11:00)
Mimics natural sunrise progression. Research shows natural daylight starts at 2700K (sunrise) and peaks at 6000-6200K (midday).

| Time  | Temperature | Description              | Research Basis |
|-------|-------------|--------------------------|----------------|
| 07:00 | 2700K       | Warm sunrise             | Natural daylight start |
| 08:00 | 3500K       | Warming up               | Gradual progression |
| 09:00 | 4500K       | Approaching midday       | Building alertness |
| 10:00 | 5500K       | Nearly peak              | High alertness |
| 11:00 | ~6500K      | Peak daylight (no tint)  | Natural midday peak |

### Daytime (11:00 - 19:00)
Peak daylight color (~6500K) with no tint applied. Maintains alertness and cognitive performance.

### Evening Transition (19:00 - 22:30)
Starts 2+ hours before bedtime as recommended by research. Gradually reduces blue light to support natural melatonin production.

| Time  | Temperature | Description          | Research Basis |
|-------|-------------|----------------------|----------------|
| 19:00 | 4500K       | Begin evening transition | 2-hour pre-sleep window |
| 20:00 | 3500K       | Getting warmer       | Reducing blue light |
| 21:00 | 3000K       | Warmer still         | Supporting melatonin |
| 22:00 | 2800K       | Nearly optimal       | Minimal blue light |
| 22:30 | 2500K       | Optimal for sleep    | Research: 2500-2700K ideal |

### Night (22:30 - 07:00)
Optimal sleep warmth (2500K) maintained throughout the night. Minimal blue light exposure for best sleep quality.

## Color Temperature Guide

Color temperature is measured in Kelvin (K):

- **2000-3000K**: Very warm (orange/red) - Candlelight, sunset, optimal for night
- **3500-4500K**: Warm (yellow-white) - Transitional, easy on eyes
- **5000-5500K**: Neutral white - Balanced, similar to daylight
- **6500K+**: Cool (blue-white) - Bright daylight, computer default

**Lower values** = Warmer (more orange/red) light, better for evening
**Higher values** = Cooler (more blue) light, better for daytime

## Scientific Research Basis

This configuration is based on academic research into circadian rhythms, melatonin production, and optimal lighting:

### Key Research Findings

**Natural Daylight Cycle:**
- Natural daylight follows a pattern: 2700K (sunrise) → 6000-6200K (midday) → 2700K (sunset)
- Our configuration mimics this natural cycle

**Evening Blue Light & Melatonin:**
- Study comparing 6500K vs 3000K vs 2500K light in the evening:
  - **6500K** (cool blue): Maximum melatonin suppression
  - **3000K** (warm): Moderate melatonin suppression
  - **2500K** (very warm): Minimal melatonin suppression
- Recommendation: Use 2500-2700K for evening/night

**Critical Timing Windows (CDC/NIOSH):**
- **Morning (1 hour before/after wake-up)**: Bright, cool light (5000-6500K) advances circadian rhythm ~1 hour earlier
- **Evening (2 hours before bedtime)**: Warm light (2500-3000K) needed - bright/cool light delays circadian rhythm ~2 hours

**Practical Application:**
Research consistently shows that warmer color temperatures with lower intensity in the evening support better sleep quality and natural melatonin production.

## How It Works

Hyprsunset applies color temperature profiles based on the time of day:

1. **Profile-based**: Each `profile` block defines a color temperature for a specific time
2. **Automatic switching**: Hyprsunset automatically switches between profiles at the specified times
3. **Smooth transitions**: The gradual hourly changes create smooth, barely noticeable transitions
4. **Identity mode**: Using `identity = true` removes all tinting and returns to normal display
5. **Research-aligned**: Schedule matches natural daylight cycles and circadian rhythm research

## Reloading Configuration

After making changes to the configuration file, restart hyprsunset:

```bash
pkill hyprsunset && hyprsunset &
```

Or if you want to check if it's running first:

```bash
pkill hyprsunset
sleep 0.5
hyprsunset &
```

## Customization

### Adjusting transition times

Edit `~/.config/hypr/hyprsunset.conf` and modify the `time` values:

```
profile {
    time = 19:00  # Change this to start evening transition earlier/later
    temperature = 5000
}
```

### Adjusting warmth levels

Modify the `temperature` values to make the screen warmer (lower) or cooler (higher):

```
profile {
    time = 22:30
    temperature = 2700  # Lower = warmer, Higher = cooler
}
```

**Research-based recommendations:**
- Morning start: 2700K (matches natural sunrise)
- Midday peak: 6000-6500K (matches natural daylight)
- Evening start: 4500K (begin 2+ hours before bed)
- Night/Sleep: 2500-2700K (optimal for melatonin production)
- Daytime: `identity = true` or 6500K

### Adding more transition steps

To make transitions even more gradual, add additional profiles:

```
profile {
    time = 19:30
    temperature = 4500
}

profile {
    time = 20:30
    temperature = 3750
}
```

### Creating a custom schedule

You can create any schedule you want. For example, different settings for weekends:

```
# Early riser schedule
profile {
    time = 06:00
    temperature = 3000
}

profile {
    time = 09:00
    identity = true
}
```

## Troubleshooting

### Hyprsunset not applying changes

1. Check if hyprsunset is running:
   ```bash
   ps aux | grep hyprsunset
   ```

2. Restart hyprsunset:
   ```bash
   pkill hyprsunset && hyprsunset &
   ```

3. Check for configuration errors:
   ```bash
   hyprsunset --validate  # If available
   ```

### Screen color doesn't match expected temperature

- Hyprsunset applies changes based on system time
- Verify your system time is correct: `date`
- Ensure the config file has proper syntax (matching braces, correct time format)

### Hyprsunset not starting on boot

Add hyprsunset to your Hyprland autostart in `~/.config/hypr/hyprland.conf`:

```
exec-once = hyprsunset
```

### Profile changes don't take effect immediately

Hyprsunset only switches profiles when the time matches. If you set a profile for 19:00 and it's currently 19:30, you'll need to wait until tomorrow at 19:00 to see it applied, or manually restart hyprsunset to force a check.

To force immediate application, restart hyprsunset:
```bash
pkill hyprsunset && hyprsunset &
```

### Screen is too warm/cool

Adjust the temperature values in the configuration:
- Too warm/orange: Increase temperature values (e.g., 2700 → 3500)
- Too cool/blue: Decrease temperature values (e.g., 5000 → 4000)

## Understanding the Configuration Format

Each profile block follows this structure:

```
profile {
    time = HH:MM
    temperature = VALUE
}
```

Or for no tint:

```
profile {
    time = HH:MM
    identity = true
}
```

**Rules:**
- Time must be in 24-hour format (HH:MM)
- Temperature values typically range from 1000K to 10000K
- Use `identity = true` for normal screen color (no filter)
- Profiles apply in chronological order
- The most recent profile remains active until the next one

## Benefits

### Scientifically Validated Benefits

- **Improved melatonin production**: 2500K evening light produces minimal melatonin suppression (vs. significant suppression at 6500K)
- **Better sleep quality**: Research shows warm evening light improves sleep onset by 30+ minutes
- **Circadian rhythm support**: Matches natural daylight cycle (2700K sunrise → 6500K midday → 2500K night)
- **Reduced eye strain**: Warmer colors reduce blue light exposure in evening
- **Enhanced cognitive performance**: Cool light during daytime maintains alertness

### Practical Benefits

- **Gradual adaptation**: Smooth hourly transitions prevent sudden brightness changes
- **Natural rhythm**: Mimics the natural progression of sunlight throughout the day
- **Customizable**: Fully adjustable to your schedule and preferences
- **Evidence-based**: Configuration based on CDC/NIOSH and academic research

## Notes

- Changes to the config file require a hyprsunset restart to take effect
- Temperature values are persistent - once set, they remain until the next profile time
- The `identity = true` setting removes all color filtering
- Lower temperatures reduce blue light more effectively
- Hyprsunset works per-monitor and applies to all outputs
- State is managed by hyprsunset daemon based on system time
- Configuration is optimized based on academic research from CDC/NIOSH and peer-reviewed studies

## Research References

This configuration is based on findings from:

1. **CDC/NIOSH Studies** on circadian rhythm and light exposure timing
   - Morning light (5000-6500K) advances circadian rhythm
   - Evening bright light delays circadian rhythm by ~2 hours

2. **Academic Studies on Melatonin Suppression**
   - Studies comparing 6500K, 3000K, and 2500K light in evening hours
   - Research showing 2500-2700K produces minimal melatonin suppression

3. **Natural Daylight Cycle Research**
   - Natural daylight pattern: 2700K (sunrise) → 6000-6200K (midday) → 2700K (sunset)
   - Importance of mimicking natural light patterns for circadian health

4. **Sleep Quality Research**
   - Warm evening light (2500-3000K) improves sleep onset by 30+ minutes
   - Blue light exposure 2 hours before bed significantly impacts sleep quality

For optimal results, combine this lighting schedule with other sleep hygiene practices (consistent sleep schedule, dark sleeping environment, etc.).
