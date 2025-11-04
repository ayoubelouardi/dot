#!/bin/bash

# This script installs .ttf font files to the user's ~/.fonts directory on Debian.
# Usage: ./fonts.sh /path/to/font/files

set -euo pipefail

# Check if source directory is provided
if [[ $# -ne 1 ]]; then
  echo "❌ Usage: $0 /path/to/font/files"
  exit 1
fi

SRC_DIR="$1"
DEST_DIR="$HOME/.fonts"

# Verify source directory exists
if [[ ! -d "$SRC_DIR" ]]; then
  echo "❌ Error: Source directory '$SRC_DIR' does not exist."
  exit 1
fi

# Create destination directory if it doesn't exist
mkdir -p "$DEST_DIR"

# Copy .ttf files
echo "📁 Copying .ttf files from '$SRC_DIR' to '$DEST_DIR'..."
find "$SRC_DIR" -type f -iname '*.ttf' -exec cp -v {} "$DEST_DIR"/ \;

# Set permissions
echo "🔒 Setting permissions to 644 for font files..."
find "$DEST_DIR" -type f -iname '*.ttf' -exec chmod 644 {} \;

# Update font cache
echo "🔄 Updating font cache..."
fc-cache -f -v

echo "✅ Font installation completed successfully (user-local)."

