#!/bin/bash
# Install PlatformIO for ESP32 development
set -e

# Check if already installed
if command -v pio &>/dev/null; then
    echo "PlatformIO already installed: $(pio --version)"
    exit 0
fi

echo "Installing PlatformIO..."
uv tool install platformio

# Fix for esptoolpy dependencies
~/.local/share/uv/tools/platformio/bin/python -m ensurepip 2>/dev/null || true
uv pip install --quiet --python ~/.local/share/uv/tools/platformio/bin/python pyserial colorama

# Verify
export PATH="/home/distiller/.local/bin:$PATH"
echo "Installed: $(pio --version)"
echo "Add to PATH: export PATH=\"/home/distiller/.local/bin:\$PATH\""
