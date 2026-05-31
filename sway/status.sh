#!/usr/bin/env bash
set -uo pipefail

SEP="|"
ICON_SEP=" "
WEATHER_CACHE_TTL=3600  # seconds (1h)
MAX_SSID_LEN=14
is_num() { [[ "$1" =~ ^[0-9]+$ ]]; }
has_cmd() { command -v "$1" &>/dev/null; }

main() {

# date
date_str="$(date "+%H:%M %a %d/%m")"

# battery info
battery_sum=0
battery_count=0
any_charging=false
any_low=false
battery_devices=""

if has_cmd upower; then
  battery_devices="$(upower --enumerate 2>/dev/null | grep -E 'battery' || true)"
  if [[ -n "$battery_devices" ]]; then
    while IFS= read -r dev; do
      info="$(upower --show-info "$dev" 2>/dev/null || true)"
      [[ -z "$info" ]] && continue
      percent="$(awk -F': *' '/percentage/ {gsub(/%/,"",$2); print $2}' <<<"$info" | head -n1)"
      state="$(awk -F': *' '/state/ {print $2}' <<<"$info" | head -n1)"

      if [[ -n "${percent}" ]]; then
        battery_sum=$((battery_sum + percent))
        battery_count=$((battery_count + 1))
        (( percent <= 15 )) && any_low=true
      fi

      [[ "$state" == "charging" ]] && any_charging=true
    done <<< "$battery_devices"
  fi
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

# fan rpm
fan_rpm=""
fan_file="/proc/acpi/ibm/fan"
if [[ -r "$fan_file" ]]; then
  fan_rpm="$(awk '/^speed:/ {print $2}' "$fan_file")"
  if [[ -n "$fan_rpm" ]]; then
    fan_rpm="🌀 ${fan_rpm}"
  fi
fi

# cpu frequency
cpu_freq=""
freq_file="/sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq"
if [[ -r "$freq_file" ]]; then
  cpu_freq="$(awk '{printf "%.1fGHz", $1/1000000}' "$freq_file")"
fi

# memory
mem_used="$(free -h | awk '/Mem:/ {print $3 "/" $2}')"

# storage
storage_used="$(df -h / | awk 'NR==2 {print $3 "/" $2 " (" $5 ")"}')"

# network
net_str="❌"
if has_cmd nmcli; then
  ssid="$(nmcli -t -f active,ssid dev wifi 2>/dev/null | awk -F: '$1=="yes"{print $2; exit}')"
  if [[ -n "${ssid}" ]]; then
    net_str="📶 ${ssid:0:$MAX_SSID_LEN}"
  elif nmcli -t -f TYPE,STATE dev status 2>/dev/null | grep -q '^ethernet:connected$'; then
    net_str="🌐 Ethernet"
  fi
fi

# network speed
net_speed_str=""
net_iface="$(ip -o route get 1 2>/dev/null | awk '{print $5; exit}')"
if [[ -n "$net_iface" ]]; then
  rx_path="/sys/class/net/$net_iface/statistics/rx_bytes"
  tx_path="/sys/class/net/$net_iface/statistics/tx_bytes"
  if [[ -r "$rx_path" && -r "$tx_path" ]]; then
    rx_now=$(cat "$rx_path" 2>/dev/null || echo 0)
    tx_now=$(cat "$tx_path" 2>/dev/null || echo 0)
    now=$(date +%s)
    state_file="/tmp/sway-net-state"
    if [[ -r "$state_file" ]]; then
      read prev_ts prev_rx prev_tx < "$state_file" || true
      if is_num "$prev_ts" && is_num "$prev_rx" && is_num "$prev_tx"; then
        elapsed=$(( now - prev_ts ))
        if (( elapsed > 0 )) && (( rx_now >= prev_rx )) && (( tx_now >= prev_tx )); then
          rx_bps=$(( (rx_now - prev_rx) / elapsed ))
          tx_bps=$(( (tx_now - prev_tx) / elapsed ))
          read rx_fmt tx_fmt <<< $(awk -v r="$rx_bps" -v t="$tx_bps" '
            function f(b) { if(b>1073741824) return sprintf("%.1fG", b/1073741824); else if(b>1048576) return sprintf("%.1fM", b/1048576); else if(b>1024) return sprintf("%.0fK", b/1024); else return sprintf("%dB", b) }
            BEGIN { print f(r), f(t) }') || true
          net_speed_str="$(printf "↓%4s ↑%4s" "$rx_fmt" "$tx_fmt")"
        fi
      fi
    fi
    echo "$now $rx_now $tx_now" > "$state_file"
  fi
fi

# power consumption
power_str=""

# Try RAPL data (from rapl-power systemd service)
if [[ -r /tmp/sway-power ]]; then
  read ts rest < /tmp/sway-power || true
  now=$(date +%s)
  if is_num "$ts" && (( now - ts < 10 )); then
    for kv in $rest; do
      case "$kv" in
        psys=*) power_str="🔌 ${kv#psys=}W"; break ;;
      esac
    done
    if [[ -z "$power_str" ]]; then
      for kv in $rest; do
        case "$kv" in
          package=*) power_str="💻 ${kv#package=}W"; break ;;
        esac
      done
    fi
  fi
fi

# Fallback: upower battery discharge rate
if [[ -z "$power_str" && -n "$battery_devices" ]] && has_cmd upower; then
  total_rate=0
  any_discharging=false
  while IFS= read -r dev; do
    info="$(upower --show-info "$dev" 2>/dev/null || true)"
    state="$(awk -F': *' '/state/ {print $2}' <<<"$info" | head -n1)"
    rate="$(awk -F': *' '/energy-rate/ {gsub(/,/,".",$2); print $2}' <<<"$info" | head -n1)"
    if [[ "$state" == "discharging" && -n "$rate" ]]; then
      total_rate=$(awk -v t="$total_rate" -v r="$rate" 'BEGIN { printf "%.1f", t + r }')
      any_discharging=true
    fi
  done <<< "$battery_devices"
  if [[ "$any_discharging" == "true" ]]; then
    power_str="🔋 ${total_rate}W"
  fi
fi

# Fallback: CPU load estimation (i5-6300U TDP = 15W)
if [[ -z "$power_str" ]]; then
  tdp=15
  load_pct=$(awk -v l="$load" -v c="$cores" 'BEGIN{ if(c>0) printf "%.2f", (l/c)*100; else print 0 }')
  est=$(awk -v l="$load_pct" -v t="$tdp" 'BEGIN{ printf "%.1f", (l/100) * t }')
  if (( $(awk -v e="$est" 'BEGIN{ print (e > 0) }') )); then
    power_str="⚡ ${est}W"
  fi
fi

# weather (cached, re-fetch every 1h)
weather_str=""
weather_cache="/tmp/sway-weather"

has_internet() { ip route show default &>/dev/null; }

if has_cmd curl; then
  should_fetch=false
  if [[ -r "$weather_cache" ]]; then
    cached="$(< "$weather_cache")"
    age=$(( $(date +%s) - $(stat -c %Y "$weather_cache" 2>/dev/null || echo 0) ))
    if [[ $age -gt $WEATHER_CACHE_TTL || -z "$cached" || "$cached" == *DOCTYPE* || "$cached" == *html* ]]; then
      should_fetch=true
    fi
  else
    should_fetch=true
  fi

  if $should_fetch && has_internet; then
    curl -sLm 3 "wttr.in/?format=2" 2>/dev/null | tr -d '[:space:]' > "$weather_cache" || true
  fi

  weather_str="$(< "$weather_cache")"
fi

echo "💻 ${cpu_usage} ${cpu_temp} ${cpu_freq} ${fan_rpm}${SEP}🧠 ${mem_used}${SEP}💾 ${storage_used}${SEP}${battery_icon}${SEP}${net_str} ${net_speed_str}${SEP}${power_str}${SEP}${weather_str}${SEP}<span foreground='#888888'>${date_str}</span>"
}

main || true

