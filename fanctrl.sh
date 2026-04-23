#!/bin/bash

FAN_CONTROL_PATH="/proc/acpi/ibm/fan"

echo "Select mode:"
echo "  1) TUI (Terminal)"
echo "  2) GUI (Graphical)"
echo
read -rp "Choose mode [1]: " MODE

MODE="${MODE:-1}"

if [[ "$MODE" == "2" ]]; then
    if ! command -v zenity &>/dev/null; then
        echo "zenity is not installed. Install it first: sudo apt install zenity"
        exit 1
    fi

    if [[ $EUID -ne 0 ]]; then
        zenity --error --text="Run as root (sudo)"
        exit 1
    fi

    if [[ ! -w $FAN_CONTROL_PATH ]]; then
        zenity --error --text="Cannot access $FAN_CONTROL_PATH. Is thinkpad_acpi loaded with fan_control=1?"
        exit 1
    fi

    CHOICE=$(zenity --list \
      --title="ThinkPad Fan Control" \
      --text="Choose fan level:" \
      --radiolist \
      --column "Pick" --column "Level" --column "Description" \
      TRUE  "auto"       "Automatic (Recommended Default)" \
      FALSE "0"          "Off (For low-load or meetings)" \
      FALSE "3"          "Medium (Quiet Baseline)" \
      FALSE "7"          "Max (Pre-emptive Cooling)" \
      FALSE "disengaged" "Full Blast (Emergency Only)")

    if [[ -n "$CHOICE" ]]; then
        echo "level $CHOICE" | sudo tee "$FAN_CONTROL_PATH" > /dev/null
        zenity --info --text="Fan set to: $CHOICE"
    fi
else
    if [[ $EUID -ne 0 ]]; then
        echo "This script must be run as root. Use: sudo $0"
        exit 1
    fi

    if [[ ! -w $FAN_CONTROL_PATH ]]; then
        echo "Cannot access $FAN_CONTROL_PATH. Is thinkpad_acpi loaded with fan_control=1?"
        exit 1
    fi

    echo "Fan Speed Control for ThinkPad"
    echo "Choose a fan level:"
    echo "  0 = off"
    echo "  1-7 = low to high"
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
fi