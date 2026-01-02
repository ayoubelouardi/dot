#!/usr/bin/env bash

# date
date_str=$(date "+%a %m-%d %H:%M:%S")

# battery info (average of all batteries)
battery_devices=$(upower --enumerate | grep battery)
battery_icon=""
battery_sum=0
battery_count=0

for dev in $battery_devices; do
    info=$(upower --show-info "$dev")
    percent=$(echo "$info" | grep percentage | awk '{print $2}' | tr -d '%')
    battery_sum=$((battery_sum + percent))
    battery_count=$((battery_count + 1))

    if echo "$info" | grep -q 'battery-low-symbolic'; then
        battery_icon=🪫
    elif echo "$info" | grep -q 'charging'; then
        battery_icon=🔌
    fi
done
[ -z "$battery_icon" ] && battery_icon=🔋
if [ "$battery_count" -gt 0 ]; then
    avg_percent=$((battery_sum / battery_count))
    battery_str="${avg_percent}%"
else
    battery_str="N/A"
fi

# cpu usage (normalized load average)
cores=$(nproc)
load=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}')
cpu_usage=$(echo "$load $cores" | awk '{printf "%.0f%%", ($1/$2)*100}')

# cpu temperature
cpu_temp=$(awk '{printf "%.1f°C", $1/1000}' /sys/class/thermal/thermal_zone0/temp)

# memory usage
mem_used=$(free -h | awk '/Mem:/ {print $3 "/" $2}')

# disk usage
disk_used=$(df -h / | awk 'NR==2 {print $3 "/" $2}')

# network status (SSID only, no throughput)
ssid=$(nmcli -t -f active,ssid dev wifi | grep '^yes' | cut -d: -f2)
if [ -n "$ssid" ]; then
    net_icon="📶"
    net_str="$ssid"
else
    wired=$(nmcli -t -f DEVICE,STATE dev | grep ethernet | grep connected | cut -d: -f1)
    if [ -n "$wired" ]; then
        net_icon="🔌"
        net_str="Ethernet"
    else
        net_icon="❌"
        net_str="No Network"
    fi
fi

# weather (cached every 4 hours)
cache_file="/tmp/weather_cache"
if [ ! -s "$cache_file" ] || [ $(( $(date +%s) - $(stat -c %Y "$cache_file") )) -gt 14400 ]; then
    curl -s 'wttr.in/Casablanca?format=%t+%w' > "$cache_file" || echo "N/A" > "$cache_file"
fi
weather=$(cat "$cache_file")

echo "CPU: $cpu_usage ($cpu_temp) | RAM: $mem_used | Bat: $battery_str $battery_icon | Net: $net_icon $net_str | $weather | $date_str"

