#!/bin/bash

set -e  # Exit on error

# Base directory of the dotfiles repo
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# installing gh
(type -p wget >/dev/null || (sudo apt update && sudo apt-get install wget -y)) \
	&& sudo mkdir -p -m 755 /etc/apt/keyrings \
        && out=$(mktemp) && wget -nv -O$out https://cli.github.com/packages/githubcli-archive-keyring.gpg \
        && cat $out | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
	&& sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
	&& echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
	&& sudo apt update \
	&& sudo apt install gh -y

# installing vim-plug
curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

# removeing all the games bloat debian 12
sudo apt purge iagno lightsoff four-in-a-row gnome-robots pegsolitaire gnome-2048 hitori gnome-klotski gnome-mines gnome-mahjongg gnome-sudoku quadrapassel swell-foop gnome-tetravex gnome-taquin aisleriot gnome-chess five-or-more gnome-nibbles tali
sudo apt autoremove


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


update
