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

# Run a step without letting its failure abort the rest of the update
FAILED_STEPS=()
step() {
    local description="$1"
    shift
    log "$description..."
    if "$@"; then
        success "$description."
    else
        local rc=$?
        error "$description failed (exit $rc), continuing."
        FAILED_STEPS+=("$description")
    fi
}

step "Updating APT package list" apt update -y
step "Upgrading installed packages" apt full-upgrade -y
step "Fixing broken dependencies" apt --fix-broken install -y
step "Removing unused packages" apt autoremove -y
step "Cleaning package cache" apt clean

# Check if snap is installed before refreshing
if command -v snap >/dev/null 2>&1; then
    step "Updating Snap packages" snap refresh
else
    log "Snap not installed, skipping..."
fi

# Source nvm to make npm available
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/nvm.sh" ]; then
    [ -n "${SUDO_USER:-}" ] && HOME="$(eval echo ~$SUDO_USER)"
    # shellcheck source=/dev/null
    . "$SCRIPT_DIR/nvm.sh"
fi

# Check if npm is installed before updating
if command -v npm >/dev/null 2>&1; then
    step "Updating NPM packages" npm update -g
else
    log "NPM not installed, skipping..."
fi

if [ ${#FAILED_STEPS[@]} -gt 0 ]; then
    error "Finished with ${#FAILED_STEPS[@]} failed step(s):"
    printf '  - %s\n' "${FAILED_STEPS[@]}"
    exit 1
fi

success "System update and cleanup completed successfully!"

