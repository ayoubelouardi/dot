#!/usr/bin/env bash
# Install the 30-minute suspend-to-hibernate delay for battery-guard.
# Run with: sudo bash ~/.config/dot/script/install-battery-guard.sh
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "Run this with sudo: sudo bash $0" >&2
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$SCRIPT_DIR/../sway/systemd/battery-guard-sleep.conf"
DEST="/etc/systemd/sleep.conf.d/battery-guard.conf"

install -Dm644 "$SRC" "$DEST"
echo "Installed $DEST"
echo
echo "Effective sleep config:"
systemd-analyze cat-config systemd/sleep.conf | grep -v '^#' | grep -v '^$'
