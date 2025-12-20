#!/bin/bash
# Find the ESP32 serial port (the one with open permissions, not the protected internal MCU)
set -e

for port in /dev/ttyACM*; do
    [ -e "$port" ] || continue
    # Check if group is dialout (open) vs root (protected)
    if stat -c '%G' "$port" | grep -q dialout; then
        echo "$port"
        exit 0
    fi
done

# Fallback: check for 0666 permissions
for port in /dev/ttyACM*; do
    [ -e "$port" ] || continue
    perms=$(stat -c '%a' "$port")
    if [ "$perms" = "666" ]; then
        echo "$port"
        exit 0
    fi
done

echo "No ESP32 port found" >&2
exit 1
