# bash_rc default

# Enable color support for ls and add handy aliases
if [ -x /usr/bin/dircolors ]; then
    # Load user-specific dircolors if available, otherwise system defaults
    if [ -r ~/.dircolors ]; then
        eval "$(dircolors -b ~/.dircolors)"
    else
        eval "$(dircolors -b)"
    fi

    # Common aliases with color enabled
    alias ls='ls --color=auto'
    alias dir='dir --color=auto'
    alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi




# shortcuts
alias l='ls -A'
alias ll='ls -lAinh'
alias v='vim -p'
alias nv='nvim -p'
alias o='open'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias ghostscript='/usr/bin/gs'
alias less='less -R'
alias rm='rm -v'
alias diff='diff --color'
alias grep='grep --color'
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
alias rm-exe='rm $(find -mindepth 1 -executable -print)'
# alias old-find='find'
alias find='fdfind'

# navigation
alias alx='cd ~/Projects/alx'
alias wiki='cd ~/Projects/wiki'
alias learn='cd ~/Projects/learn'
alias learnc='cd ~/Projects/learn/c'
alias learnpy='cd ~/Projects/learn/py'
alias webs='cd ~/Projects/websites/'
alias repos='cd ~/Projects/repos/'
alias games='cd ~/Projects/games/'
alias mlm='cd ~/Projects/websites/MLM_Software'



# Git Aliases
alias gs='git status '		# Show current status
alias gss='git status -s'	# Show current status short
alias ga='git add'		# Stage changes
alias gaa='git add -A'		# Stage all (including deletions)
alias gc='git commit -m'	# Commit with message
alias gca='git commit --amend'	# Amend last commit
alias gd='git diff'		# Diff changes
alias gp='git push'		# Push changes
alias gpl='git pull'		# Pull latest changes
alias gco='git checkout'	# Switch branches
alias gcb='git checkout -b'	# Create and switch to new branch
alias gl='git log --oneline --graph --decorate'  # Pretty log
alias gb='git branch'		# List branches
alias gcl='git clone'		# Clone a repository
alias gst='git stash'		# Stash current changes
alias gsp='git stash pop'	# Apply and remove latest stash
alias git-finish='ga . && gc'  # add everything and commit

# config
alias dot-files='cd ~/.config/dot/'
alias upbash='source ~/.bashrc'
alias editvim='vim ~/.vimrc'
alias editnvim='nvim ~/.config/nvim/'
alias editalias='vim ~/.bash_aliases'
alias editbash='vim ~/.bashrc'
alias fanctrl='sudo bash ~/.config/dot/fanctrl.sh'

# update
alias yupdate='sudo bash ~/.config/dot/update.sh'


# other
alias rmswap='rm .*.swp'
alias vps='bash ~/.config/dot/vps.sh'
alias phone='bash ~/.config/dot/phone.sh'



# show packages details.
apt_details() {
    if [[ -z "$1" ]]; then
        echo "Usage: apt_details <package>"
        return 1
    fi

    {
        echo "=== apt show $1 ==="
        apt show "$1"

        echo -e "\n=== apt-cache policy $1 ==="
        apt-cache policy "$1"

        echo -e "\n=== apt-file list $1 ==="
        apt-file list "$1"
    } | less -R
}

# function for faster dev
ccfast() {
    # Check if at least one argument is provided
    if [ $# -lt 1 ]; then
        echo "Usage: ccfast <source.c> [extra compiler flags]"
        return 1
    fi

    local src="$1"

    # Check if the first argument is a .c file
    if [[ "$src" != *.c ]]; then
        echo "Error: first argument must be a C source file (*.c)"
        echo "Usage: ccfast <source.c> [extra compiler flags]"
        return 1
    fi

    # Remove .c extension for output name
    local out="${src%.c}"

    # Default flags
    local CFLAGS="-std=c99 -g -Wall -Wextra -pedantic -Werror -Wmissing-declarations"

    # Compile
    gcc $CFLAGS "$src" "${@:2}" -o "$out"
    if [ $? -eq 0 ]; then
        echo ""
        echo "Compilation successful. Running ./$out ..."
        echo ""
        "./$out"
    else
        echo "Compilation failed."
        return 1
    fi
}

