#!/usr/bin/env bash

NOT_DURATION=500

case "$1" in
    volume-up)
        pactl set-sink-volume @DEFAULT_SINK@ +5%
        VOL=$(pactl get-sink-volume @DEFAULT_SINK@ | awk '{print $5}' | head -n1)
        notify-send -t $NOT_DURATION "Audio" "Volume: $VOL"
        ;;
    volume-down)
        pactl set-sink-volume @DEFAULT_SINK@ -5%
        VOL=$(pactl get-sink-volume @DEFAULT_SINK@ | awk '{print $5}' | head -n1)
        notify-send -t $NOT_DURATION "Audio" "Volume: $VOL"
        ;;
    volume-mute)
        pactl set-sink-mute @DEFAULT_SINK@ toggle
        MUTE=$(pactl get-sink-mute @DEFAULT_SINK@ | awk '{print $2}')
        notify-send -t $NOT_DURATION "Audio" "Mute: $MUTE"
        ;;
    mic-mute)
        pactl set-source-mute @DEFAULT_SOURCE@ toggle
        MUTE=$(pactl get-source-mute @DEFAULT_SOURCE@ | awk '{print $2}')
        notify-send -t $NOT_DURATION "Microphone" "Mute: $MUTE"
        ;;
    brightness-up)
        brightnessctl set +5%
        BRIGHT=$(brightnessctl -m | cut -d, -f4)
        notify-send -t $NOT_DURATION "Brightness" "Level: ${BRIGHT}"
        ;;
    brightness-down)
        brightnessctl set 5%-
        BRIGHT=$(brightnessctl -m | cut -d, -f4)
        notify-send -t $NOT_DURATION "Brightness" "Level: ${BRIGHT}"
        ;;
    screenshot)
        FILE="$HOME/Pictures/screenshot-$(date +%F_%T).png"
        grim "$FILE"
        notify-send -t $NOT_DURATION "Screenshot" "Saved to $FILE"
        ;;
    *)
        echo "Usage: $0 {volume-up|volume-down|volume-mute|mic-mute|brightness-up|brightness-down|screenshot}"
        ;;
esac
<organization>
