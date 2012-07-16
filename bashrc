# If not running interactively, don't do anything
[ -z "$PS1" ] && return


# TERM --------------------------------------------------------------

case "$TERM" in
	xterm*) TERM=xterm-256color
esac


# ALIASES -----------------------------------------------------------

# Defaults for tree (color, show hidden, ignore version control)
alias tree="tree -Ca -I '.svn|.git' --dirsfirst"

# Easy editing of config files
alias nanorc="$EDITOR ~/.nanorc"
alias bashrc="$EDITOR ~/.bashrc"
alias vimrc="$EDITOR ~/.vimrc"

# Use GitHub enhancements with git
hash hub &>/dev/null && alias git=hub

alias v=vim
alias c=clear
alias r=rails

# Git abbreviations
alias g='git'
alias ga='git add'
alias gc='git commit'
alias gca='git commit -a'
alias gp='git push'
alias gl='git log'
alias gs='git status'
alias gd='git diff'
alias gdc='git diff --cached'
alias gb='git branch'
alias gch='git checkout'
alias gpu='git pull'
alias gcl='git clone'


# FUNCTIONS ---------------------------------------------------------

# Give visual indicator of exit status of previous command.
result () {
	if [ $? = 0 ]; then
		echo -e "\033[0;32m----- Success -----\033[0m"
	else
		echo -e "\033[0;33m----- Failure -----\033[0m"
	fi
}


# PROMPT ------------------------------------------------------------

# Source script that defines __git_ps1 ()
if [ -f ~/bin/git-completion.bash ] ; then
	source ~/bin/git-completion.bash
	
	# Show a "*" next to branch name for unstaged changes, a "+"
	# for staged changes, and a "$" for stashed changes.
	GIT_PS1_SHOWDIRTYSTATE=1
	GIT_PS1_SHOWSTASHSTATE=1
fi

COLOR_BOLD="\[\e[1m\]"
COLOR_DEFAULT="\[\e[0m\]"
COLOR_BLACK="\[\e[30m\]"
COLOR_BOLD_YELLOW="\[\e[1;33m\]"

# Number of path components to include in \w
PROMPT_DIRTRIM=2

# pwd (gitbranch) $
PS1="$COLOR_BOLD\w$COLOR_BOLD_YELLOW"'$(__git_ps1)'"$COLOR_DEFAULT$COLOR_BOLD \$ $COLOR_DEFAULT"
PS2="$COLOR_BOLD > $COLOR_DEFAULT"


# HISTORY and BOOKMARKS ---------------------------------------------

# Don't put duplicate lines in the history. See bash(1) for more options.
export HISTCONTROL=ignoredups

# Bookmark directories.
if [ -f ~/bin/bmark.sh ] ; then
	source ~/bin/bmark.sh
fi


# COLORS ------------------------------------------------------------

export CLICOLOR=1
export GREP_OPTIONS='--color=auto'

