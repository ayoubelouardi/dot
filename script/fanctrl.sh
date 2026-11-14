#!/usr/bin/env bash
#
# ThinkPad fan control (thinkpad_acpi).
#
# Usage:
#   fanctrl.sh                 # interactive (GUI when there is no terminal)
#   fanctrl.sh 3               # set level directly
#   fanctrl.sh auto            # hand control back to the EC
#   fanctrl.sh status          # show the current fan status
#   fanctrl.sh --tui|--gui     # force an interface
#
set -uo pipefail

FAN_CONTROL_PATH="/proc/acpi/ibm/fan"
VALID_LEVELS="0 1 2 3 4 5 6 7 auto disengaged full-speed status"

SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
ORIG_ARGS=("$@")

IS_GUI=0
FORCE_TUI=0
LEVEL_ARG=""

err() { printf '%s\n' "$*" >&2; }

usage() {
    sed -n '3,11p' "$SCRIPT_PATH" | sed 's/^# \{0,1\}//'
}

# --- argument parsing ------------------------------------------------------
while [[ $# -gt 0 ]]; do
    case "$1" in
        -g|--gui) IS_GUI=1 ;;
        -t|--tui) IS_GUI=0; FORCE_TUI=1 ;;
        -h|--help) usage; exit 0 ;;
        --) shift; break ;;
        -*) err "Unknown option: $1"; usage >&2; exit 1 ;;
        *) LEVEL_ARG="$1" ;;
    esac
    shift
done
[[ $# -gt 0 ]] && LEVEL_ARG="$1"

# Validate before elevating, so a typo does not prompt for a password.
if [[ -n "$LEVEL_ARG" && "$LEVEL_ARG" != "status" ]]; then
    [[ " $VALID_LEVELS " == *" $LEVEL_ARG "* ]] || {
        err "Invalid level: $LEVEL_ARG. Valid: $VALID_LEVELS"
        exit 1
    }
fi

# No terminal -> assume we were launched from a keybinding / desktop entry.
[[ $FORCE_TUI -eq 0 && ! -t 0 ]] && IS_GUI=1

# --- privilege handling ----------------------------------------------------
# The fan control file is root-only; re-exec ourselves with elevation once.
ensure_root() {
    [[ $EUID -eq 0 ]] && return 0
    if [[ -t 0 ]] && command -v sudo >/dev/null 2>&1; then
        exec sudo -- bash "$SCRIPT_PATH" "${ORIG_ARGS[@]}"
    fi
    if command -v pkexec >/dev/null 2>&1; then
        exec pkexec bash "$SCRIPT_PATH" "${ORIG_ARGS[@]}"
    fi
    if command -v sudo >/dev/null 2>&1; then
        exec sudo -- bash "$SCRIPT_PATH" "${ORIG_ARGS[@]}"
    fi
    err "Root privileges are required to control the fan."
    err "Run: sudo $SCRIPT_PATH"
    exit 1
}

if [[ ! -r "$FAN_CONTROL_PATH" ]]; then
    err "Cannot access $FAN_CONTROL_PATH."
    err "Is thinkpad_acpi loaded with fan_control=1?"
    exit 1
fi

ensure_root

# Whoever launched us (sudo keeps SUDO_USER, pkexec exposes PKEXEC_UID).
GUI_USER="${SUDO_USER:-}"
if [[ -z "$GUI_USER" && -n "${PKEXEC_UID:-}" ]]; then
    GUI_USER="$(getent passwd "$PKEXEC_UID" | cut -d: -f1)"
fi

# --- zenity / GUI helpers --------------------------------------------------
run_zenity() {
    if [[ $EUID -eq 0 && -n "$GUI_USER" && "$GUI_USER" != "root" ]]; then
        local uid home
        uid="$(id -u "$GUI_USER")"
        home="$(getent passwd "$GUI_USER" | cut -d: -f6)"
        local -a envs=(XDG_RUNTIME_DIR="/run/user/$uid" "HOME=$home")

        local wayland="${WAYLAND_DISPLAY:-}" display="${DISPLAY:-}"
        local sock
        for sock in /run/user/"$uid"/wayland-*; do
            [[ -S "$sock" ]] && { wayland="$(basename "$sock")"; break; }
        done

        if [[ -z "$display" ]]; then
            local pid val
            for pid in $(pgrep -u "$uid" 2>/dev/null); do
                [[ -r "/proc/$pid/environ" ]] || continue
                val="$(tr '\0' '\n' < "/proc/$pid/environ" 2>/dev/null |
                       sed -n 's/^DISPLAY=//p' | head -n1)"
                [[ -n "$val" ]] && { display="$val"; break; }
            done
        fi

        [[ -n "$wayland" ]] && envs+=("WAYLAND_DISPLAY=$wayland")
        [[ -n "$display" ]] && envs+=("DISPLAY=$display")

        sudo -u "$GUI_USER" env "${envs[@]}" zenity "$@"
    else
        zenity "$@"
    fi
}

# --- fan helpers -----------------------------------------------------------
fan_status() {
    if [[ -r "$FAN_CONTROL_PATH" ]]; then
        cat "$FAN_CONTROL_PATH"
    else
        sudo cat "$FAN_CONTROL_PATH"
    fi
}

fan_write() {
    local cmd="$1"
    if [[ -w "$FAN_CONTROL_PATH" ]]; then
        printf '%s\n' "$cmd" > "$FAN_CONTROL_PATH"
    else
        printf '%s\n' "$cmd" | sudo tee "$FAN_CONTROL_PATH" >/dev/null
    fi
}

current_level() {
    fan_status | awk '/^level:/ {print $2; exit}'
}

get_level() {
    local level="$1"
    [[ "$level" == "full-speed" ]] && level="disengaged"
    printf '%s' "$level"
}

is_valid_level() {
    local needle=" $VALID_LEVELS "
    [[ "$needle" == *" $1 "* ]]
}

# Apply a level and keep the kernel watchdog from reverting it.
# The watchdog re-arms on every write, so disable it *after* setting the level.
apply_level() {
    local level
    level="$(get_level "$1")"

    if ! fan_write "level $level"; then
        return 1
    fi

    if [[ "$level" == "auto" ]]; then
        fan_write "watchdog 30" || return 1
    else
        fan_write "watchdog 0" || return 1
    fi

    sleep 0.5
    local applied
    applied="$(current_level)"
    [[ "$applied" == "$level" ]]
}

show_status() {
    local status
    if ! status="$(fan_status)"; then
        err "Could not read fan status."
        return 1
    fi
    printf '%s\n' "$status"
}

# --- interfaces ------------------------------------------------------------
gui_run() {
    if ! command -v zenity >/dev/null 2>&1; then
        err "zenity is not installed. Install it first: sudo apt install zenity"
        exit 1
    fi

    local choice
    choice="$(run_zenity --list \
        --title="ThinkPad Fan Control" \
        --text="Choose fan level (current: $(current_level)):" \
        --radiolist --hide-column=1 --print-column=2 \
        --column "Pick" --column "Level" --column "Description" \
        --height=420 \
        TRUE  "auto"       "Automatic (Recommended default)" \
        FALSE "0"          "Off (low load or meetings)" \
        FALSE "1"          "Lowest" \
        FALSE "2"          "Very low" \
        FALSE "3"          "Low (quiet baseline)" \
        FALSE "4"          "Medium-low" \
        FALSE "5"          "Medium" \
        FALSE "6"          "Medium-high" \
        FALSE "7"          "High (max safe)" \
        FALSE "disengaged" "Full blast (emergency only)")"
    local rc=$?

    # 1 = cancelled, 5 = timeout.
    [[ $rc -ne 0 ]] && return 0
    [[ -z "$choice" ]] && return 0
    choice="$(get_level "$choice")"

    if apply_level "$choice"; then
        run_zenity --info --title="ThinkPad Fan Control" \
            --text="Fan level set to: $choice"
    else
        run_zenity --error --title="ThinkPad Fan Control" \
            --text="Failed to set fan level to $choice.\n\n$(fan_status 2>&1)"
        exit 1
    fi
}

tui_run() {
    local level="$LEVEL_ARG"

    if [[ -n "$level" && "$level" != "status" ]]; then
        is_valid_level "$level" || {
            err "Invalid level: $level. Valid: $VALID_LEVELS"
            exit 1
        }
        printf 'Setting fan level to: %s\n' "$level"
        apply_level "$level" || { err "Failed to set fan level to $level"; exit 1; }
        show_status
        return
    fi

    echo "Fan Speed Control for ThinkPad"
    echo "Current status:"
    show_status
    echo
    echo "Choose a fan level:"
    echo "  0 = off"
    echo "  1-7 = low to high"
    echo "  auto = automatic mode"
    echo "  disengaged = max (loudest)"
    echo "  status = show current fan info"
    echo

    read -rp "Enter fan level (0-7, auto, disengaged, status) [auto]: " level
    level="${level:-auto}"

    if [[ "$level" == "status" ]]; then
        show_status
        return
    fi

    is_valid_level "$level" || {
        err "Invalid level: $level. Valid: $VALID_LEVELS"
        exit 1
    }

    printf 'Setting fan level to: %s\n' "$level"
    apply_level "$level" || { err "Failed to set fan level to $level"; exit 1; }
    show_status
}

if [[ -z "$LEVEL_ARG" && $IS_GUI -eq 0 && -t 0 ]]; then
    echo "Select mode:"
    echo "  1) TUI (Terminal)"
    echo "  2) GUI (Graphical)"
    echo
    read -rp "Choose mode [1]: " mode
    [[ "${mode:-1}" == "2" ]] && IS_GUI=1
fi

if [[ "$LEVEL_ARG" == "status" ]]; then
    show_status
elif [[ $IS_GUI -eq 1 ]]; then
    gui_run
else
    tui_run
fi
