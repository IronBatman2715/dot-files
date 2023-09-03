# If not running interactively, don't do anything
case $- in
  *i*) ;;
    *) return;;
esac

## Bash completion
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

## History
HISTTIMEFORMAT="%F %T " # format with time
HISTCONTROL=ignoreboth # no duplicate lines or lines starting with space
shopt -s histappend # append instead of overwriting

# Limit to 100 lines
HISTSIZE=100
HISTFILESIZE=200

## Misc
shopt -s checkwinsize # update LINES and COLUMNS on window resize if necessary

## Aliases

# Add color support for common commands
alias ls="ls --color"
alias grep="grep --color"
alias egrep="egrep --color"
alias fgrep="fgrep --color"

# Run aliases file if present
if [ -f ~/.bash_aliases ]; then
  . ~/.bash_aliases
fi

## Colors

# Attribute codes:
# 0=none 1=bold 4=underscore 5=blink 7=reverse 8=concealed
# Text color codes:
# 30=black 31=red 32=green 33=yellow 34=blue 35=magenta 36=cyan 37=white
# Background color codes:
# 40=black 41=red 42=green 43=yellow 44=blue 45=magenta 46=cyan 47=white

# Color escape sequences
function color() {
  case $# in
    2)
      # Color $2 with $1
      printf "\e[%sm%s" "$1" "$2"
      ;;
    1)
      # Echo specified color
      printf "\e[%sm" "$1"
      ;;
    *)
      # Reset to default color
      printf "\e[0m"
      ;;
  esac
}

## Prompt

# Print git branch if current directory is a git repository
function git_branch() {
  if [ -d .git ] ; then
    printf "$(np_color)($(np_color '0;36')%s$(np_color)) " "$(__git_ps1 '%s')"
  fi
}
# Bash prompt Non-printing color escape sequences
function np_color() {
  local output=''
  case $# in
    2)
      # Color $2 with $1
      output="$(color $1 $2)"
      ;;
    1)
      # Echo specified color
      output="$(color $1)"
      ;;
    *)
      # Reset to default color
      output="$(color)"
      ;;
  esac

  printf '\[%s\]' "$output"
}

function build_prompt() {
  PS1="$(np_color '0;32')[\t] $(git_branch)$(np_color '1;34')\W$(np_color)\$ "
}

PROMPT_COMMAND=build_prompt

## Custom functions

# Print network information
function netinfo() {
  printf "$(color '0;36')DATE$(color): %s\n" "$(date)"
  printf "$(color '0;36')USER@HOSTNAME$(color): %s@%s\n" "$(whoami)" "$(hostname)"
  #printf "$(color '0;36')LOCAL IP ADDR$(color): %s\n" "$()"
  printf "$(color '0;36')PUBLIC IP ADDR$(color): %s\n" "$(curl -s ifconfig.me)"
}

# Run setups for installed programs if present.
# 
# WILL NEED TO MOVE SETUPS THERE MANUALLY AS PROGRAMS TYPICALLY WRITE HERE OR TO .bash_profile
if [ -f ~/.bash_program_setups ]; then
  . ~/.bash_program_setups
fi
