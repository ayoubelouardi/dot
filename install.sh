#!/bin/bash
set -e  # Exit on error

# Base directory of the dotfiles repo
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# insatll base
sudo apt update -y
sudo apt install curl git vim -y


# --- Install GitHub CLI (gh) ---
(type -p wget >/dev/null || (sudo apt update && sudo apt install wget -y)) \
    && sudo mkdir -p -m 755 /etc/apt/keyrings \
    && out=$(mktemp) && wget -nv -O$out https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    && cat $out | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
    && sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && sudo mkdir -p -m 755 /etc/apt/sources.list.d \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && sudo apt update \
    && sudo apt install gh -y

# --- Install vim-plug ---
curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

# --- Remove GNOME games bloat (Debian 12) ---
sudo apt purge -y iagno lightsoff four-in-a-row gnome-robots pegsolitaire gnome-2048 \
  hitori gnome-klotski gnome-mines gnome-mahjongg gnome-sudoku quadrapassel swell-foop \
  gnome-tetravex gnome-taquin aisleriot gnome-chess five-or-more gnome-nibbles tali
sudo apt autoremove -y

# --- Dotfiles to link ---
FILES=(
    ".bash_aliases"
    ".bashrc"
    ".bash_logout"
    ".profile"
    ".vimrc"
    ".inputrc"
    ".tmux.conf"
)
DIRECTORIES=(
    "sway"
    "kitty"
    "rofi"
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

link_dir_config() {
  local src="$DOTFILES_DIR/$1"
  local dest="$HOME/.config/$1"
  if [ -e "$dest" ] || [ -L "$dest" ]; then
    echo "Removing existing directory or symlink: $dest"
    rm -rf "$dest"
  fi
  echo "Linking $src → $dest"
  ln -s "$src" "$dest"
}

# Link files into $HOME
for file in "${FILES[@]}"; do
  link_file "$file"
done

# Link directories into ~/.config
for dir in "${DIRECTORIES[@]}"; do
  link_dir_config "$dir"
done

# --- Source bash configuration --- 
if [ -n "$BASH_VERSION" ]; then 
    echo "Reloading bash configuration..."
    # Source .bashrc so aliases and settings take effect immediately 
    source "$HOME/.bashrc"
fi

echo "✅ Dotfiles installation complete!"
echo "-> it will be usefull if you did this command right now"
echo "$ yupdate"

