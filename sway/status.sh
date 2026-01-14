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
    elif [ -z "$battery_icon" ] && echo "$info" | grep -q 'charging'; then
        # only set charging if no low-battery warning
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

# cpu temperature (prefer CPU zone if available)
cpu_zone=$(grep -l "x86_pkg_temp" /sys/class/thermal/thermal_zone*/type 2>/dev/null | head -n1)
cpu_dir=$(dirname "$cpu_zone")
[ -z "$cpu_dir" ] && cpu_dir="/sys/class/thermal/thermal_zone0"
cpu_temp=$(awk '{printf "%.0f°C", $1/1000}' "$cpu_dir"/temp)

# memory usage
mem_used=$(free -h | awk '/Mem:/ {print $3 "/" $2}')

# disk usage (show / and /home if present)
disk_root=$(df -h / | awk 'NR==2 {print $3 "/" $2}')
if mountpoint -q /home; then
    disk_home=$(df -h /home | awk 'NR==2 {print $3 "/" $2}')
    disk_used="$disk_root (/)|$disk_home (/home)"
else
    disk_used="$disk_root"
fi

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

# weather (cached every 4 hours, refresh if N/A)
cache_file="/tmp/weather_cache"
refresh_needed=false
if [ ! -s "$cache_file" ] || [ $(( $(date +%s) - $(stat -c %Y "$cache_file") )) -gt 14400 ]; then
    refresh_needed=true
elif grep -q "N/A" "$cache_file"; then
    refresh_needed=true
fi

if $refresh_needed; then
    curl -s 'wttr.in/Casablanca?format=%t+%w' > "$cache_file" || echo "N/A" > "$cache_file"
fi
weather=$(cat "$cache_file")

echo "💻$cpu_usage/$cpu_temp|🧠$mem_used|🔋$battery_str$battery_icon|$net_icon $net_str|💾$disk_used|$weather|$date_str"
# echo "CPU: $cpu_usage/$cpu_temp|RAM: $mem_used|🔋:$battery_str $battery_icon|$net_icon $net_str|Disk: $disk_used|$weather|$date_str"

