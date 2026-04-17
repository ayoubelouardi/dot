#!/usr/bin/env bash
set -euo pipefail

SEP="  "
ICON_SEP=" "

# date
date_str="$(date "+%H:%M %a %d/%m")"

# battery info
battery_devices="$(upower --enumerate | grep -E 'battery' || true)"
battery_sum=0
battery_count=0
any_charging=false
any_low=false

if [[ -n "${battery_devices}" ]]; then
  while IFS= read -r dev; do
    info="$(upower --show-info "$dev" 2>/dev/null || true)"
    percent="$(awk -F': *' '/percentage/ {gsub(/%/,"",$2); print $2}' <<<"$info" | head -n1)"
    state="$(awk -F': *' '/state/ {print $2}' <<<"$info" | head -n1)"

    if [[ -n "${percent}" ]]; then
      battery_sum=$((battery_sum + percent))
      battery_count=$((battery_count + 1))
      if (( percent <= 15 )); then
        any_low=true
      fi
    fi

    if [[ "${state:-}" == "charging" ]]; then
      any_charging=true
    fi
  done <<< "$battery_devices"
fi

if (( battery_count > 0 )); then
  avg_percent=$((battery_sum / battery_count))
  battery_str="${avg_percent}%"
else
  battery_str="N/A"
fi

# battery icon
if [[ "${battery_str}" == "N/A" ]]; then
  battery_icon=""
elif [[ "$any_low" == "true" ]]; then
  battery_icon="<span foreground='#ff5555'>${battery_str}</span>"
elif [[ "$any_charging" == "true" ]]; then
  battery_icon="<span foreground='#50fa7b'>${battery_str}</span> ⚡"
else
  battery_icon="${battery_str}"
fi

# cpu
cores="$(nproc)"
load="$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | tr -d ',')"
cpu_usage="$(awk -v l="$load" -v c="$cores" 'BEGIN{ if(c>0) printf "%.0f%%", (l/c)*100; else print "N/A" }')"

# cpu temp
cpu_temp="N/A"
cpu_zone="$(grep -lE '^x86_pkg_temp$' /sys/class/thermal/thermal_zone*/type 2>/dev/null | head -n1 || true)"
if [[ -z "$cpu_zone" ]]; then
  cpu_zone="$(ls -1 /sys/class/thermal/thermal_zone*/temp 2>/dev/null | head -n1 || true)"
  cpu_dir="$(dirname "${cpu_zone:-/sys/class/thermal/thermal_zone0/temp}")"
else
  cpu_dir="$(dirname "$cpu_zone")"
fi

if [[ -r "$cpu_dir/temp" ]]; then
  cpu_temp="$(awk '{printf "%.0f°C", $1/1000}' "$cpu_dir/temp")"
fi

# memory
mem_used="$(free -h | awk '/Mem:/ {print $3 "/" $2}')"

# network
ssid="$(nmcli -t -f active,ssid dev wifi 2>/dev/null | awk -F: '$1=="yes"{print $2; exit}')"
if [[ -n "${ssid}" ]]; then
  net_str="📶 $ssid"
elif nmcli -t -f TYPE,STATE dev status 2>/dev/null | grep -q '^ethernet:connected$'; then
  net_str="🌐 Ethernet"
else
  net_str="❌"
fi

echo "💻 ${cpu_usage} ${cpu_temp}${SEP}🧠 ${mem_used}${SEP}${battery_icon}${SEP}${net_str}${SEP}<span foreground='#888888'>${date_str}</span>"

