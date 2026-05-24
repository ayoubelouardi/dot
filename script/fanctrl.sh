#!/bin/bash

FAN_CONTROL_PATH="/proc/acpi/ibm/fan"
IS_GUI=0

write_fan_level() {
    local level="$1"
    if [[ -w "$FAN_CONTROL_PATH" ]]; then
        echo "level $level" > "$FAN_CONTROL_PATH"
    else
        echo "level $level" | sudo tee "$FAN_CONTROL_PATH" > /dev/null
    fi
}

read_fan_status() {
    if [[ -r "$FAN_CONTROL_PATH" ]]; then
        cat "$FAN_CONTROL_PATH"
    else
        sudo cat "$FAN_CONTROL_PATH"
    fi
}

run_zenity() {
    if [[ $EUID -eq 0 && -n "$SUDO_USER" ]]; then
        local user_uid=$(id -u "$SUDO_USER")
        local env=()

        env+=(XDG_RUNTIME_DIR="/run/user/$user_uid")

        if [[ -z "$DISPLAY" ]]; then
            local pid=$(pgrep -u "$SUDO_USER" -x swaybar 2>/dev/null | head -1)
            [[ -z "$pid" ]] && pid=$(pgrep -u "$SUDO_USER" -x swaybg 2>/dev/null | head -1)
            [[ -z "$pid" ]] && pid=$(pgrep -u "$SUDO_USER" -x swaync 2>/dev/null | head -1)
            if [[ -n "$pid" ]]; then
                local val=$(cat "/proc/$pid/environ" 2>/dev/null | tr '\0' '\n' | grep '^DISPLAY=' | cut -d= -f2-)
                [[ -n "$val" ]] && DISPLAY="$val"
            fi
        fi
        [[ -n "$DISPLAY" ]] && env+=(DISPLAY="$DISPLAY")

        if [[ -z "$WAYLAND_DISPLAY" ]]; then
            for sock in /run/user/"$user_uid"/wayland-*; do
                if [[ -S "$sock" ]]; then
                    WAYLAND_DISPLAY=$(basename "$sock")
                    break
                fi
            done
        fi
        [[ -n "$WAYLAND_DISPLAY" ]] && env+=(WAYLAND_DISPLAY="$WAYLAND_DISPLAY")

        sudo -u "$SUDO_USER" "${env[@]}" zenity "$@"
    else
        zenity "$@"
    fi
}

echo "Select mode:"
echo "  1) TUI (Terminal)"
echo "  2) GUI (Graphical)"
echo
read -rp "Choose mode [1]: " MODE

MODE="${MODE:-1}"

if [[ "$MODE" == "2" ]]; then
    IS_GUI=1
    if ! command -v zenity &>/dev/null; then
        echo "zenity is not installed. Install it first: sudo apt install zenity" >&2
        exit 1
    fi

    CHOICE=$(run_zenity --list \
      --title="ThinkPad Fan Control" \
      --text="Choose fan level:" \
      --radiolist \
      --column "Pick" --column "Level" --column "Description" \
      --height=400 \
      TRUE  "auto"       "Automatic (Recommended Default)" \
      FALSE "0"          "Off (For low-load or meetings)" \
      FALSE "1"          "Lowest" \
      FALSE "2"          "Very Low" \
      FALSE "3"          "Low (Quiet Baseline)" \
      FALSE "4"          "Medium-Low" \
      FALSE "5"          "Medium" \
      FALSE "6"          "Medium-High" \
      FALSE "7"          "High (Max Safe)" \
      FALSE "disengaged" "Full Blast (Emergency Only)")

    if [[ -n "$CHOICE" ]]; then
        if write_fan_level "$CHOICE"; then
            run_zenity --info --text="Fan set to: $CHOICE"
        else
            run_zenity --error --text="Failed to set fan level to $CHOICE"
            exit 1
        fi
    fi
else
    [[ $EUID -eq 0 ]] || { echo "This script must be run as root. Use: sudo $0" >&2; exit 1; }
    [[ -w "$FAN_CONTROL_PATH" ]] || { echo "Cannot access $FAN_CONTROL_PATH. Is thinkpad_acpi loaded with fan_control=1?" >&2; exit 1; }

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
        read_fan_status
        exit 0
    fi

    VALID_LEVELS="0 1 2 3 4 5 6 7 auto disengaged"
    if [[ ! " $VALID_LEVELS " =~ " $LEVEL " ]]; then
        echo "Invalid level: $LEVEL. Valid: $VALID_LEVELS" >&2
        exit 1
    fi

    echo "Setting fan level to: $LEVEL"
    write_fan_level "$LEVEL" || { echo "Failed to set fan level to $LEVEL" >&2; exit 1; }
    sleep 0.5
    read_fan_status
fi
