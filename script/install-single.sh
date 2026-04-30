#!/bin/bash
set -e

# Base directory of the dotfiles repo (parent of script/)
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [ $# -lt 1 ]; then
    echo "Usage: $0 <app-name>"
    echo "Available apps: sway kitty rofi zellij ollama htop fastfetch swaync"
    exit 1
fi

target="$1"
src="$DOTFILES_DIR/$target"
dest="$HOME/.config/$target"

# Check if target exists in dotfiles repo
if [ ! -d "$src" ]; then
    echo "Error: '$target' directory not found in $DOTFILES_DIR"
    exit 1
fi

# Remove existing symlink or directory
if [ -e "$dest" ] || [ -L "$dest" ]; then
    echo "Removing existing: $dest"
    rm -rf "$dest"
fi

# Link the config directory
echo "Linking $src → $dest"
ln -s "$src" "$dest"

echo "✅ Successfully installed $target config"
