# Multi-Vendor GPU Monitoring for Waybar

This waybar setup includes adaptive GPU monitoring that automatically detects and supports multiple GPU vendors across different systems.

## Supported GPU Vendors

### 1. **Nvidia GPUs** (Discrete and Mobile)
- **Detection Method**: `nvidia-smi` command
- **Metrics Collected**:
  - GPU Usage (%)
  - Temperature (°C)
  - VRAM Usage (GB and %)
  - Power Draw (W)
- **Requirements**: `nvidia-smi` must be installed (comes with Nvidia drivers)
- **Priority**: Checked first (discrete GPU priority)

### 2. **AMD GPUs** (Radeon and RDNA series)
- **Detection Method**: sysfs interfaces (`/sys/class/drm/card*/device/`)
- **Metrics Collected**:
  - GPU Usage (%) via `gpu_busy_percent`
  - Temperature - Edge (°C)
  - Temperature - Junction (°C)
  - Temperature - Memory (°C)
  - VRAM Usage (GB and %) via `mem_info_vram_*`
  - Power Draw (W) via hwmon
- **Requirements**: amdgpu kernel driver (built-in on most Linux systems)
- **Priority**: Checked second

### 3. **Intel GPUs** (Integrated Graphics)
- **Detection Method**: PCI vendor ID check (0x8086)
- **Metrics Collected**: Limited without additional tools
- **Requirements**: i915 kernel driver (built-in)
- **Enhanced Monitoring**: Install `intel_gpu_top` from `intel-gpu-tools` package for detailed metrics
- **Priority**: Checked last (integrated GPU fallback)

## How It Works

### Automatic Detection Flow

```
1. Check for nvidia-smi → Use Nvidia path
   ├─ Success: Collect Nvidia metrics
   └─ Fail: Continue to AMD check

2. Check for AMD sysfs paths → Use AMD path
   ├─ Success: Collect AMD metrics
   └─ Fail: Continue to Intel check

3. Check for Intel vendor ID → Use Intel path
   ├─ Success: Show Intel GPU (limited metrics)
   └─ Fail: Show "No supported GPU detected"
```

### Scripts

#### `gpu.sh` - Main GPU Metrics
- **Update Interval**: 5 seconds
- **Rolling Average**: 15 seconds (last 3 samples)
- **Output Format**: JSON for waybar
- **Features**:
  - Automatic vendor detection
  - Vendor-specific metric collection
  - Rolling average for smoother readings
  - Collapse/expand state support

#### `power.sh` - GPU Power & Cost
- **Update Interval**: 20 seconds
- **Rolling Average**: 60 seconds (last 3 samples)
- **Output Format**: JSON for waybar
- **Features**:
  - Calculates electricity cost per hour
  - Configurable electricity rate (default: €0.35/kWh)
  - Vendor-agnostic power collection

## Installation & Setup

### Prerequisites

**For Nvidia GPUs:**
```bash
# nvidia-smi should be available with your Nvidia drivers
nvidia-smi --version
```

**For AMD GPUs:**
```bash
# amdgpu driver should be loaded
lsmod | grep amdgpu
```

**For Intel GPUs (Enhanced):**
```bash
# Install intel-gpu-tools for detailed monitoring
sudo pacman -S intel-gpu-tools  # Arch Linux
sudo apt install intel-gpu-tools # Debian/Ubuntu
```

### Waybar Configuration

The scripts are already configured in waybar's `config.jsonc`:

```jsonc
"custom/gpu": {
  "exec": "$HOME/.config/waybar/scripts/gpu.sh",
  "format": "GPU {}%",
  "interval": 5,
  "return-type": "json",
  "tooltip": true,
  "signal": 4
}

"custom/power": {
  "exec": "$HOME/.config/waybar/scripts/power.sh",
  "format": "€{}",
  "interval": 20,
  "return-type": "json",
  "tooltip": true
}
```

### Customization

#### Electricity Rate
Edit `/home/surface/Repos/GHyprland/waybar/scripts/power.sh`:
```bash
# Change the electricity cost per kWh
COST_PER_KWH=0.35  # Your rate here
```

#### GPU Card Priority
The scripts automatically prioritize discrete GPUs over integrated GPUs. If you have both Nvidia and AMD GPUs, Nvidia will be selected by default.

## Testing

### Test GPU Metrics
```bash
bash ~/.config/waybar/scripts/gpu.sh
```

**Expected Output (Nvidia):**
```json
{"text":"5","tooltip":"GPU: Nvidia\nUsage: 5%\nTemperature: 41°C\nVRAM: 0.5GB / 4.0GB (13%)"}
```

**Expected Output (AMD):**
```json
{"text":"12","tooltip":"GPU: AMD\nUsage: 12%\nTemperature (Edge): 62°C\nTemperature (Junction): 58°C\nTemperature (Memory): 55°C\nVRAM: 4.2GB / 12.0GB (35%)"}
```

**Expected Output (Intel):**
```json
{"text":"N/A","tooltip":"GPU: Intel (integrated)\nLimited metrics available\nInstall intel_gpu_top for detailed monitoring"}
```

### Test Power Metrics
```bash
bash ~/.config/waybar/scripts/power.sh
```

**Expected Output:**
```json
{"text":"0.003","tooltip":"GPU Power: 15.2W\nCost per hour: €0.003\nCost per day: €0.07\nElectricity rate: €0.35/kWh"}
```

## Troubleshooting

### Nvidia GPU Shows N/A
- **Check nvidia-smi**: `nvidia-smi`
- **Check drivers**: `lsmod | grep nvidia`
- **Reinstall**: `sudo pacman -S nvidia-utils` (Arch) or equivalent

### AMD GPU Shows N/A
- **Check sysfs paths**: `ls /sys/class/drm/card*/device/gpu_busy_percent`
- **Check driver**: `lsmod | grep amdgpu`
- **Check hwmon**: `ls /sys/class/drm/card*/device/hwmon/`

### Intel GPU Shows Limited Metrics
- **Install intel_gpu_top**: `sudo pacman -S intel-gpu-tools`
- **Check vendor**: `lspci | grep VGA` should show Intel

### Wrong GPU Selected
If you have multiple GPUs and the wrong one is selected:
1. Check detection order in `gpu.sh:detect_and_collect_gpu_metrics()`
2. Modify priority by reordering the detection blocks
3. Or explicitly set a specific card by modifying the scripts

## System Examples

### Laptop (Intel iGPU + Nvidia dGPU)
- **Selected**: Nvidia GeForce RTX 3050 Ti
- **Method**: nvidia-smi
- **Metrics**: Full (Usage, Temp, VRAM, Power)

### Desktop (AMD CPU with iGPU + AMD Radeon dGPU)
- **Selected**: AMD Radeon RX 9070
- **Method**: sysfs (amdgpu driver)
- **Metrics**: Full (Usage, 3x Temps, VRAM, Power)

### Mini PC (Intel CPU with Iris Xe iGPU)
- **Selected**: Intel Iris Xe Graphics
- **Method**: Vendor ID detection
- **Metrics**: Limited (requires intel_gpu_top for details)

## Performance Impact

- **CPU Usage**: ~0.01-0.05% average
- **Memory**: ~5-10 MB for history files
- **Disk I/O**: Negligible (temp files in `/tmp`)
- **Network**: None

## Files

- `/home/surface/Repos/GHyprland/waybar/scripts/gpu.sh` - Main GPU metrics script
- `/home/surface/Repos/GHyprland/waybar/scripts/power.sh` - Power and cost script
- `/tmp/waybar_gpu_history` - GPU usage rolling average data
- `/tmp/waybar_gpu_cost_history` - Power rolling average data
- `/tmp/waybar-system-metrics-state` - Collapse/expand state

## Contributing

When adding support for new GPU vendors:

1. Add detection logic to `detect_and_collect_gpu_metrics()` in `gpu.sh`
2. Collect metrics and set `gpu_vendor` variable
3. Add corresponding tooltip case in the vendor switch statement
4. Update `power.sh` if power metrics are available
5. Test on the target hardware
6. Document in this file

## Recent Fixes

### CPU Percentage Calculation Fix (2025-11-07)

**Issue**: Per-process CPU percentages were showing values higher than total system CPU usage. For example, a single process would show 100%+ usage even though total CPU was only 10%.

**Root Cause**: The `ps aux` command reports CPU usage as a percentage of **one CPU core**, not total system CPU. On a multi-core system:
- A process using 100% of one core shows as **100%** in `ps aux`
- On an 8-core system, that's actually **100/8 = 12.5%** of total system CPU capacity

**Fix**: Updated `cpu.sh` (line 80-123) to:
1. Get the number of CPU cores using `nproc`
2. Divide aggregated per-process CPU percentages by the number of cores
3. Display true system CPU percentages instead of per-core percentages

**Result**: Per-process percentages now correctly represent system-wide CPU usage and will always be less than or equal to the total CPU usage.

## References

- [Waybar Custom Modules](https://github.com/Alexays/Waybar/wiki/Module:-Custom)
- [Nvidia SMI Documentation](https://developer.nvidia.com/nvidia-system-management-interface)
- [AMDGPU Driver Documentation](https://www.kernel.org/doc/html/latest/gpu/amdgpu.html)
- [Intel GPU Tools](https://gitlab.freedesktop.org/drm/igt-gpu-tools)
