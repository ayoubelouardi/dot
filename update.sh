#!/bin/bash

# Exit immediately if a command fails, treat unset vars as errors, and fail on pipe errors
set -euo pipefail

# Colors for output
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
RESET="\033[0m"

log() {
    echo -e "${YELLOW}➤ $1${RESET}"
}

success() {
    echo -e "${GREEN}✔ $1${RESET}"
}

error() {
    echo -e "${RED}✖ $1${RESET}"
}

# Ensure script is run with sudo/root
if [[ $EUID -ne 0 ]]; then
   error "This script must be run as root (use sudo)."
   exit 1
fi

log "Updating APT package list..."
apt update -y && success "APT package list updated."

log "Upgrading installed packages..."
apt full-upgrade -y && success "System packages upgraded."

log "Fixing broken dependencies (if any)..."
apt --fix-broken install -y && success "Broken dependencies resolved."

log "Removing unused packages..."
apt autoremove -y && apt clean && success "Unused packages removed and cache cleaned."

# Check if snap is installed before refreshing
if command -v snap >/dev/null 2>&1; then
    log "Updating Snap packages..."
    snap refresh && success "Snap packages updated."
else
    log "Snap not installed, skipping..."
fi

success "System update and cleanup completed successfully!"

