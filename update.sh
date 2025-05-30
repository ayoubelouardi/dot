#!/bin/bash

# Exit on error
set -e

echo "🔄 Updating APT package list..."
sudo apt update -y

echo "⬆️ Upgrading installed packages..."
sudo apt full-upgrade -y

echo "🛠️ Fixing broken dependencies if any..."
sudo apt --fix-broken install -y

echo "🧹 Removing unused packages..."
sudo apt autoremove -y

echo "📦 Updating Snap packages..."
sudo snap refresh

echo "✅ System update and cleanup completed successfully."

