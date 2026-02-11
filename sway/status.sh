#!/usr/bin/env bash
set -euo pipefail

# date
date_str="$(date "+%a %m-%d %H:%M:%S")"

# battery info (average of all batteries)
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

      # low battery threshold (tweak if you want)
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
  avg_percent=0
fi

# battery icon based on computed status
if [[ "${battery_str}" == "N/A" ]]; then
  battery_icon="🔋"
elif [[ "$any_low" == "true" ]]; then
  battery_icon="🪫"
elif [[ "$any_charging" == "true" ]]; then
  battery_icon="🔌"
else
  battery_icon="🔋"
fi

# cpu usage (normalized load average)
cores="$(nproc)"
load="$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | tr -d ',')"
cpu_usage="$(awk -v l="$load" -v c="$cores" 'BEGIN{ if(c>0) printf "%.0f%%", (l/c)*100; else print "N/A" }')"

# cpu temperature (best-effort)
cpu_temp="N/A"
cpu_zone=""
# try common x86 package sensor type, else fallback
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

# memory usage
mem_used="$(free -h | awk '/Mem:/ {print $3 "/" $2}')"

# disk usage (show / and /home if present)
disk_root="$(df -h / | awk 'NR==2 {print $3 "/" $2}')"
if mountpoint -q /home; then
  disk_home="$(df -h /home | awk 'NR==2 {print $3 "/" $2}')"
  disk_used="$disk_root (/)|$disk_home (/home)"
else
  disk_used="$disk_root"
fi

# network status (SSID or Ethernet)
ssid="$(nmcli -t -f active,ssid dev wifi 2>/dev/null | awk -F: '$1=="yes"{print $2; exit}')"
if [[ -n "${ssid}" ]]; then
  net_icon="📶"
  net_str="$ssid"
else
  # reliable wired check
  if nmcli -t -f TYPE,STATE dev status 2>/dev/null | grep -q '^ethernet:connected$'; then
    net_icon="🔌"
    net_str="Ethernet"
  else
    net_icon="❌"
    net_str="No Network"
  fi
fi

# weather (cached every 4 hours, refresh if missing or N/A)
# cache_file="/tmp/weather_cache"
# now_epoch="$(date +%s)"
# cache_epoch=0
# if [[ -f "$cache_file" ]]; then
#   cache_epoch="$(stat -c %Y "$cache_file" 2>/dev/null || echo 0)"
# fi
# 
# refresh_needed=false
# if [[ ! -s "$cache_file" ]]; then
#   refresh_needed=true
# elif (( now_epoch - cache_epoch > 14400 )); then
#   refresh_needed=true
# elif grep -q "N/A" "$cache_file"; then
#   refresh_needed=true
# fi
# 
#
# 
# if [[ "$refresh_needed" == "true" ]]; then
#   # timeout so your bar never hangs
#   curl -fsS --max-time 3 'wttr.in/Casablanca?format=%t+%w' > "$cache_file" || echo "N/A" > "$cache_file"
# fi
# weather="$(cat "$cache_file" 2>/dev/null || echo "N/A")"

echo "💻$cpu_usage/$cpu_temp|🧠$mem_used|🔋:$battery_str$battery_icon|$net_icon $net_str|💾$disk_used|$date_str"

