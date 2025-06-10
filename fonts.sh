#!/bin/bash

# This script installs .ttf font files system-wide on Debian.
# Usage: sudo ./fonts.sh /path/to/font/files

set -e

# Check if running as root
if [[ $EUID -ne 0 ]]; then
  echo "Please run this script with sudo or as root."
  exit 1
fi

# Check if source directory is provided
if [[ -z "$1" ]]; then
  echo "Usage: sudo $0 /path/to/font/files"
  exit 1
fi

SRC_DIR="$1"
DEST_DIR="/usr/local/share/fonts/custom"

# Verify source directory exists
if [[ ! -d "$SRC_DIR" ]]; then
  echo "Error: Source directory '$SRC_DIR' does not exist."
  exit 1
fi

# Create destination directory if it doesn't exist
mkdir -p "$DEST_DIR"

# Copy .ttf files
echo "Copying .ttf files from $SRC_DIR to $DEST_DIR..."
cp -v "$SRC_DIR"/*.ttf "$DEST_DIR"/

# Set permissions
echo "Setting permissions to 644 for font files..."
chmod 644 "$DEST_DIR"/*.ttf

# Update font cache
echo "Updating font cache..."
fc-cache -f -v

echo "Font installation completed successfully."

