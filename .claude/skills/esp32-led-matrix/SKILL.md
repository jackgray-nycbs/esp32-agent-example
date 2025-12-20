---
name: ESP32 LED Matrix Development
description: Build, debug, and develop LED matrix games for ESP32-S3 using PlatformIO, FastLED, and shared libraries. Use when working with ESP32 LED matrices, creating games, troubleshooting hardware issues, or setting up PlatformIO projects.
allowed-tools: Read, Write, Edit, Bash, Grep, Glob
---

# ESP32 LED Matrix Development

Complete workflow for developing LED matrix games on ESP32-S3 with PlatformIO, including setup, debugging, and game development.

## Autonomous Operation Rules

**Goal: Upload code without user intervention.** Install all dependencies automatically. Only stop for genuine blockers that cannot be resolved programmatically.

**Critical patterns:**
- Always prefix pio: `export PATH="/home/distiller/.local/bin:$PATH" && pio ...`
- cd to project dir before build/upload
- Timeouts: 120000ms builds (600000ms first time)
- Auto-upload after successful build
- Detect success: `Chip is ESP32-S3`, `Hash of data verified`
- Detect failure: `pio: command not found` (missing PATH), permission denied or timeout (wrong port)
- Never use `--break-system-packages` (use uv)
- **Port selection:** Device has two MCUs. One is permission-protected (internal). Check `ls -la /dev/ttyACM*` - use the port with open permissions (`root:dialout` or `0666`), not the restricted one (`root:root`).

## What This Skill Covers

- **Setup**: Install PlatformIO, create new projects, configure build system
- **Development**: Write LED matrix games using shared libraries and templates
- **Debugging**: Fix hardware issues (colors, orientation, wiring, visualization)

## Quick Start Workflow

### 1. Check/Install PlatformIO (REQUIRED FIRST STEP)

```bash
bash scripts/install-pio.sh
```

Installs PlatformIO via uv with esptoolpy fixes. Skips if already installed. Timeout: 600000ms for first install.

### 2. Create New Game

```bash
mkdir -p examples/MyGame/src
cd examples/MyGame
```

Copy `platformio.ini` from `examples/RotatingDonut/` or create:

```ini
[env:waveshare-esp32s3-matrix]
platform = espressif32
board = adafruit_feather_esp32s3
framework = arduino
lib_deps = fastled/FastLED@^3.9.20
lib_extra_dirs = ../../lib
monitor_speed = 115200
upload_speed = 921600
```

### 3. Write Game Code

Create `src/main.cpp` from template:

```cpp
#include <FastLED.h>
#include <BoardConfig.h>
#include <MatrixUtil.h>

#define NUM_LEDS (MATRIX_WIDTH * MATRIX_HEIGHT)
CRGB leds[NUM_LEDS];

void setup() {
  Serial.begin(115200);
  unsigned long t0 = millis();
  while (!Serial && millis() - t0 < 1500) { delay(10); }
  if (Serial) MU_PrintMeta();

  MU_ADD_LEDS(LED_PIN, leds, NUM_LEDS);
  FastLED.setBrightness(BRIGHTNESS_LIMIT);
  FastLED.clear(); FastLED.show();
}

void loop() {
  FastLED.clear();

  // YOUR GAME LOGIC HERE
  for (uint8_t y=0; y<MATRIX_HEIGHT; ++y)
    for (uint8_t x=0; x<MATRIX_WIDTH; ++x)
      if ((x+y)&1) leds[MU_XY(x,y)] = CRGB(30,30,30);

  FastLED.show();
  if (Serial) MU_SendFrameCSV(leds);
  delay(100);
}
```

### 4. Build and Upload

```bash
export PATH="/home/distiller/.local/bin:$PATH" && pio run              # Timeout: 120000ms
export PATH="/home/distiller/.local/bin:$PATH" && pio run -t upload --upload-port $(bash scripts/find-esp32-port.sh)
```

**Upload troubleshooting:**
- Success: `Connecting....` → `Writing at 0x...` progress → `Hash of data verified`
- Permission denied or timeout: Wrong port. The `find-esp32-port.sh` script detects the correct port (open permissions, not the protected internal MCU).
- Wrong device: `lsusb | grep -i esp` shows "MicroPython"/"Pico" → ask user to replug ESP32
- Note: PlatformIO auto-resets ESP32-S3 via RTS pin. BOOT+RESET button sequence is rarely needed.

### 5. Debug Hardware Issues

Run calibration pattern to check hardware:

```cpp
MU_DrawCalibration(leds);
FastLED.show();
```

Expected corners: TL=Green, TR=Red, BL=Blue, BR=White

**If colors wrong:** Edit `COLOR_ORDER` in `lib/BoardConfig/BoardConfig.h` (Waveshare uses `RGB`)

**If orientation wrong:** Edit `PANEL_ROTATION`, `PANEL_FLIP_X/Y` in `lib/BoardConfig/BoardConfig.h`

**If alternating rows mirrored:** Set `PANEL_WIRING_SERPENTINE = 0` in `lib/BoardConfig/BoardConfig.h`

### 6. Visualize in Terminal (Optional)

```bash
python3 tools/led_matrix_viz.py -p /dev/ttyACM0 -b 115200 --stats
```

Auto-configures from META line in serial output.

## Core Principles

1. **Single Source of Truth**: All hardware config in `lib/BoardConfig/BoardConfig.h`
2. **Shared Libraries**: All games use `<BoardConfig.h>` and `<MatrixUtil.h>`
3. **Always use MU_XY()**: Never manually calculate LED index
4. **No hardcoding**: Use `MATRIX_WIDTH/HEIGHT` constants
5. **Serial optional**: Guard all serial with `if (Serial)`

## Essential Functions

```cpp
// Coordinate mapping (handles wiring/orientation)
leds[MU_XY(x, y)] = CRGB::Red;

// FastLED initialization
MU_ADD_LEDS(LED_PIN, leds, NUM_LEDS);

// Serial helpers
MU_PrintMeta();           // Print config once
MU_SendFrameCSV(leds);    // Send frame for visualizer

// Debug pattern
MU_DrawCalibration(leds); // Corner markers
```

## Common Issues

| Symptom | Fix |
|---------|-----|
| Colors wrong (red→blue) | `COLOR_ORDER` in BoardConfig.h |
| Alternating rows mirrored | `PANEL_WIRING_SERPENTINE = 0` |
| Display rotated | `PANEL_ROTATION` in BoardConfig.h |
| Display mirrored | `PANEL_FLIP_X/Y` in BoardConfig.h |
| Pattern scrambled | Always use `MU_XY(x,y)` |
| Upload timeout/permission denied | Wrong port - use `bash scripts/find-esp32-port.sh` |
| Include errors | Use `<BoardConfig.h>` not quotes |
| Flash size error | Use `board = adafruit_feather_esp32s3` |

## Detailed Documentation

For comprehensive guides, see:

- **[reference/setup.md](reference/setup.md)** - PlatformIO installation, project creation, build/upload
- **[reference/debugging.md](reference/debugging.md)** - Hardware troubleshooting, visualization tools
- **[reference/development.md](reference/development.md)** - Game templates, FastLED patterns, best practices
- **[examples/](examples/)** - Code examples and game templates

## Project Structure

```
esp32-agent-example/
├── lib/                           # Shared libraries
│   ├── BoardConfig/BoardConfig.h  # Hardware config (single source of truth)
│   └── MatrixUtil/MatrixUtil.h    # Helper functions
├── examples/                      # Game projects
└── tools/led_matrix_viz.py       # Terminal visualizer
```

**Configuration:** `lib/BoardConfig/BoardConfig.h` controls all hardware settings (dimensions, pins, orientation). Change once, affects all games.
