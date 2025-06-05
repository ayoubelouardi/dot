# shortcuts
alias l='ls -A'
alias ll='ls -lAnh'
alias v='vim'
alias o='open'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias ghostscript='/usr/bin/gs'
alias alx='cd ~/Projects/alx'
alias learn='cd ~/Projects/learn'
alias learnc='cd ~/Projects/learn/c'



# Git Aliases
alias gs='git status '		# Show current status
alias gss='git status -s'	# Show current status short
alias ga='git add .'		# Stage all changes
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

# config
alias upbash='source ~/.bashrc'
alias editvim='vim ~/.vimrc'
alias editalias='vim ~/.bash_aliases'
alias editbash='vim ~/.bashrc'
alias fanctrl='sudo bash ~/.config/dot/fanctrl.sh'

# update
alias update='sudo bash ~/.config/dot/update.sh'


# XAMPP
alias start-ser='sudo /opt/lampp/lampp start'
alias stop-ser='sudo /opt/lampp/lampp stop'


# other
alias rmswap='rm .*.swp'
