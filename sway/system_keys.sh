#!/usr/bin/env bash

NOT_DURATION=500
LOGFILE="${HOME}/.cache/system_keys.log"
mkdir -p "$(dirname "$LOGFILE")"

# notify wrapper: title, body, [icon], [urgency]
notify() {
    local title="$1" body="$2" icon="$3" urgency="${4:-normal}"
    if command -v notify-send >/dev/null 2>&1; then
        if [ -n "$icon" ]; then
            notify-send -t "$NOT_DURATION" -u "$urgency" -i "$icon" "$title" "$body"
        else
            notify-send -t "$NOT_DURATION" -u "$urgency" "$title" "$body"
        fi
    else
        printf '%s: %s\n' "$title" "$body"
    fi
}

# simple logger
log() {
    printf '[%s] %s\n' "$(date --iso-8601=seconds)" "$*" >> "$LOGFILE"
}

cmd_exists() { command -v "$1" >/dev/null 2>&1; }

# Robust brightness parsing: try csv field, then fallback to any percent match
get_brightness_raw() {
    local out perc
    out=$(brightnessctl -m 2>/dev/null) || { echo "0%"; return; }
    perc=$(printf '%s' "$out" | awk -F, '{print $4}' | head -n1)
    if [ -z "$perc" ] || ! printf '%s' "$perc" | grep -q '%'; then
        perc=$(printf '%s' "$out" | grep -oE '[0-9]+%' | head -n1)
    fi
    printf '%s' "$perc"
}

get_brightness_num() {
    local raw
    raw=$(get_brightness_raw)
    printf '%s' "$(printf '%s' "$raw" | grep -oE '[0-9]+' || echo 0)"
}

# Volume parsing: get first percent occurrence
get_volume() {
    if ! cmd_exists pactl; then
        echo "n/a"
        return
    fi
    pactl get-sink-volume @DEFAULT_SINK@ 2>/dev/null | grep -oE '[0-9]+%' | head -n1 || echo '0%'
}

case "$1" in
    volume-up)
        if ! cmd_exists pactl; then
            notify "Audio" "pactl not found" "audio-input-microphone" "critical"
            log "pactl not found for volume-up"
            exit 1
        fi
        pactl set-sink-volume @DEFAULT_SINK@ +5% || log "pactl set-sink-volume failed"
        VOL=$(get_volume)
        notify "Audio" "Volume: $VOL" "audio-volume-medium" "normal"
        log "Volume changed to $VOL"
        ;;
    volume-down)
        if ! cmd_exists pactl; then
            notify "Audio" "pactl not found" "audio-input-microphone" "critical"
            log "pactl not found for volume-down"
            exit 1
        fi
        pactl set-sink-volume @DEFAULT_SINK@ -5% || log "pactl set-sink-volume failed"
        VOL=$(get_volume)
        notify "Audio" "Volume: $VOL" "audio-volume-medium" "normal"
        log "Volume changed to $VOL"
        ;;
    volume-mute)
        if ! cmd_exists pactl; then
            notify "Audio" "pactl not found" "audio-input-microphone" "critical"
            log "pactl not found for volume-mute"
            exit 1
        fi
        pactl set-sink-mute @DEFAULT_SINK@ toggle
        MUTE=$(pactl get-sink-mute @DEFAULT_SINK@ 2>/dev/null | grep -oE 'yes|no' | head -n1)
        notify "Audio" "Mute: ${MUTE:-unknown}" "audio-volume-muted" "normal"
        log "Sink mute toggled: ${MUTE:-unknown}"
        ;;
    mic-mute)
        if ! cmd_exists pactl; then
            notify "Microphone" "pactl not found" "audio-input-microphone" "critical"
            log "pactl not found for mic-mute"
            exit 1
        fi
        pactl set-source-mute @DEFAULT_SOURCE@ toggle
        MUTE=$(pactl get-source-mute @DEFAULT_SOURCE@ 2>/dev/null | grep -oE 'yes|no' | head -n1)
        notify "Microphone" "Mute: ${MUTE:-unknown}" "microphone-sensitivity-muted" "normal"
        log "Source mute toggled: ${MUTE:-unknown}"
        ;;
    brightness-up)
        if ! cmd_exists brightnessctl; then
            notify "Brightness" "brightnessctl not found" "display-brightness" "critical"
            log "brightnessctl missing for brightness-up"
            exit 1
        fi
        CURRENT=$(get_brightness_num)
        NEW=$((CURRENT + 5))
        if [ "$NEW" -gt 100 ]; then
            NEW=100
        fi
        brightnessctl set "${NEW}%" || log "brightnessctl set failed to ${NEW}%"
        BRIGHT=$(get_brightness_raw)
        notify "Brightness" "Level: ${BRIGHT}" "display-brightness" "normal"
        log "Brightness changed from ${CURRENT}% to ${NEW}%"
        ;;
    brightness-down)
        if ! cmd_exists brightnessctl; then
            notify "Brightness" "brightnessctl not found" "display-brightness" "critical"
            log "brightnessctl missing for brightness-down"
            exit 1
        fi
        CURRENT=$(get_brightness_num)
        NEW=$((CURRENT - 5))
        if [ "$NEW" -lt 1 ]; then
            NEW=1
        fi
        brightnessctl set "${NEW}%" || log "brightnessctl set failed to ${NEW}%"
        BRIGHT=$(get_brightness_raw)
        notify "Brightness" "Level: ${BRIGHT}" "display-brightness" "normal"
        log "Brightness changed from ${CURRENT}% to ${NEW}%"
        ;;
    screenshot)
        if ! cmd_exists grim; then
            notify "Screenshot" "grim not found" "camera-photo" "critical"
            log "grim not found for screenshot"
            exit 1
        fi
        mkdir -p "$HOME/Pictures"
        FILE="$HOME/Pictures/screenshot-$(date +%F_%T).png"
        if grim "$FILE"; then
            notify "Screenshot" "Saved to $FILE" "camera-photo" "normal"
            log "Screenshot saved: $FILE"
        else
            notify "Screenshot" "Failed to save to $FILE" "camera-photo" "critical"
            log "Screenshot failed: $FILE"
        fi
        ;;
    *)
        echo "Usage: $0 {volume-up|volume-down|volume-mute|mic-mute|brightness-up|brightness-down|screenshot}"
        ;;
    esac
