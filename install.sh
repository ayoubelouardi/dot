#!/bin/bash

set -e  # Exit on error

# Base directory of the dotfiles repo
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# installing vim-plug
curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

# List of dotfiles to link
FILES=(
  ".bash_aliases"
  ".bashrc"
  ".bash_logout"
  ".profile"
  ".vimrc"
)

echo "Installing dotfiles from $DOTFILES_DIR into $HOME..."

link_file() {
    local src="$DOTFILES_DIR/$1"
    local dest="$HOME/$1"

    if [ -e "$dest" ] || [ -L "$dest" ]; then
        echo "Removing existing file or symlink: $dest"
        rm -rf "$dest"
    fi

    echo "Linking $src → $dest"
    ln -s "$src" "$dest"
}

for file in "${FILES[@]}"; do
    link_file "$file"
done

echo "✅ Dotfiles installation complete!"

