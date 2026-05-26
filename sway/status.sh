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

# storage
storage_used="$(df -h / | awk 'NR==2 {print $3 "/" $2 " (" $5 ")"}')"

# network
ssid="$(nmcli -t -f active,ssid dev wifi 2>/dev/null | awk -F: '$1=="yes"{print $2; exit}')"
if [[ -n "${ssid}" ]]; then
  net_str="📶 $ssid"
elif nmcli -t -f TYPE,STATE dev status 2>/dev/null | grep -q '^ethernet:connected$'; then
  net_str="🌐 Ethernet"
else
  net_str="❌"
fi

# network speed
net_speed_str=""
net_iface="$(ip -o route get 1 2>/dev/null | awk '{print $5; exit}')"
if [[ -n "$net_iface" ]]; then
  rx_now=$(cat "/sys/class/net/$net_iface/statistics/rx_bytes" 2>/dev/null || echo 0)
  tx_now=$(cat "/sys/class/net/$net_iface/statistics/tx_bytes" 2>/dev/null || echo 0)
  now=$(date +%s)
  state_file="/tmp/sway-net-state"
  if [[ -r "$state_file" ]]; then
    read prev_ts prev_rx prev_tx < "$state_file"
    elapsed=$(( now - prev_ts ))
    if (( elapsed > 0 )); then
      rx_bps=$(( (rx_now - prev_rx) / elapsed ))
      tx_bps=$(( (tx_now - prev_tx) / elapsed ))
      rx_fmt=$(awk -v b="$rx_bps" 'BEGIN{ if(b>1073741824) printf "%.1fG", b/1073741824; else if(b>1048576) printf "%.1fM", b/1048576; else if(b>1024) printf "%.0fK", b/1024; else printf "%dB", b }')
      tx_fmt=$(awk -v b="$tx_bps" 'BEGIN{ if(b>1073741824) printf "%.1fG", b/1073741824; else if(b>1048576) printf "%.1fM", b/1048576; else if(b>1024) printf "%.0fK", b/1024; else printf "%dB", b }')
      net_speed_str="↓${rx_fmt} ↑${tx_fmt}"
    fi
  fi
  echo "$now $rx_now $tx_now" > "$state_file"
fi

# power consumption
power_str=""

# Try RAPL data (from rapl-power systemd service)
if [[ -r /tmp/sway-power ]]; then
  read ts rest < /tmp/sway-power
  now=$(date +%s)
  if (( now - ts < 10 )); then
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
if [[ -z "$power_str" && -n "$battery_devices" ]]; then
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

echo "💻 ${cpu_usage} ${cpu_temp}${SEP}🧠 ${mem_used}${SEP}💾 ${storage_used}${SEP}${battery_icon}${SEP}${net_str} ${net_speed_str}${SEP}${power_str}${SEP}<span foreground='#888888'>${date_str}</span>"

