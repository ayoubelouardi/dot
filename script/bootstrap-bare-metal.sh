#!/usr/bin/env bash
set -euo pipefail

if ! command -v apt-get >/dev/null 2>&1; then
  echo "This script requires apt-get." >&2
  exit 1
fi

sudo apt-get update
sudo apt-get install -y vim tmux fastfetch neofetch htop

shell_rc="${HOME}/.bashrc"

cat >> "${shell_rc}" <<'EOF'

# Common aliases
alias ls='ls --color=auto'
alias dir='dir --color=auto'
alias vdir='vdir --color=auto'

alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

alias l='ls -A'
alias ll='ls -lAinh'
alias nv='nvim -p'
alias v='nv'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias cls='clear'
alias ghostscript='/usr/bin/gs'
alias less='less -R'
alias rm='rm -v'
alias diff='diff --color'
alias ncdu='ncdu --color=dark'
alias readme='vim README.md'
alias p='python3'
alias untar='tar -xvzf'
alias pack-installed='dpkg --get-selections'
alias test-connection='ping -c 5 google.com'
alias cmatrix='cmatrix -C yellow'
alias fastfetch='fastfetch --color yellow'
alias icat="kitten icat"
alias ram-info='inxi -mxxz'
alias rm-exe='rm $(/usr/bin/find -mindepth 1 -type f -executable -print)'
alias old-find='/usr/bin/find'
alias find='fdfind'
alias qr-wifi='sudo nmcli dev wifi show-password'

alias gs='git status '
alias gss='git status -s'
alias ga='git add'
alias gaa='git add -A'
alias gc='git commit -m'
alias gca='git commit --amend'
alias gd='git diff'
alias gp='git push'
alias gpl='git pull'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gl='git log --oneline --graph --decorate'
alias gb='git branch'
alias gcl='git clone'
alias gst='git stash'
alias gsp='git stash pop'
alias git-finish='ga . && gc'

alias yupdate='sudo bash ~/.config/dot/script/update.sh'

alias rmswap='rm .*.swp'

# Prompt
export PS1="[\[\033[01;32m\]\u\[\033[00m\]: \[\033[01;34m\]\W\[\033[00m\]]\$ "
EOF

echo "Updated ${shell_rc}. Restart your shell or source it to apply changes."
