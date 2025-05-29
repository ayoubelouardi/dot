#!/bin/bash

# Must be run with sudo
FAN_CONTROL_PATH="/proc/acpi/ibm/fan"

if [[ $EUID -ne 0 ]]; then
    echo "❌ This script must be run as root. Use: sudo $0"
    exit 1
fi

if [[ ! -w $FAN_CONTROL_PATH ]]; then
    echo "❌ Cannot access $FAN_CONTROL_PATH. Is thinkpad_acpi loaded with fan_control=1?"
    exit 1
fi

echo "📦 Fan Speed Control for ThinkPad"
echo "Choose a fan level:"
echo "  0 = off"
echo "  1–7 = low to high"
echo "  auto = automatic mode"
echo "  disengaged = max (loudest)"
echo "  status = show current fan info"
echo

read -rp "Enter fan level (0-7, auto, disengaged, status): " LEVEL

if [[ "$LEVEL" == "status" ]]; then
    cat "$FAN_CONTROL_PATH"
    exit 0
fi

echo "Setting fan level to: $LEVEL"
echo "level $LEVEL" > "$FAN_CONTROL_PATH"
sleep 0.5
cat "$FAN_CONTROL_PATH"

