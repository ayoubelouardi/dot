#!/bin/bash

FAN_CONTROL_PATH="/proc/acpi/ibm/fan"
IS_GUI=0

fail() {
    if [[ $IS_GUI -eq 1 ]]; then
        zenity --error --text="$1" 2>/dev/null || echo "$1" >&2
    else
        echo "$1" >&2
    fi
    exit 1
}

echo "Select mode:"
echo "  1) TUI (Terminal)"
echo "  2) GUI (Graphical)"
echo
read -rp "Choose mode [1]: " MODE

MODE="${MODE:-1}"

if [[ "$MODE" == "2" ]]; then
    IS_GUI=1
    command -v zenity &>/dev/null || fail "zenity is not installed. Install it first: sudo apt install zenity"
fi

[[ $EUID -eq 0 ]] || fail "This script must be run as root. Use: sudo $0"
[[ -w "$FAN_CONTROL_PATH" ]] || fail "Cannot access $FAN_CONTROL_PATH. Is thinkpad_acpi loaded with fan_control=1?"

if [[ $IS_GUI -eq 1 ]]; then
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
        echo "level $CHOICE" > "$FAN_CONTROL_PATH" || fail "Failed to set fan level to $CHOICE"
        zenity --info --text="Fan set to: $CHOICE"
    fi
else
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

    VALID_LEVELS="0 1 2 3 4 5 6 7 auto disengaged"
    if [[ ! " $VALID_LEVELS " =~ " $LEVEL " ]]; then
        fail "Invalid level: $LEVEL. Valid: $VALID_LEVELS"
    fi

    echo "Setting fan level to: $LEVEL"
    echo "level $LEVEL" > "$FAN_CONTROL_PATH" || fail "Failed to set fan level to $LEVEL"
    sleep 0.5
    cat "$FAN_CONTROL_PATH"
fi
