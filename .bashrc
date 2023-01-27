# If not running interactively, don't do anything
case $- in
  *i*) ;;
    *) return;;
esac

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

# Non-printing color escape sequences
function np_color() {
  local PREFIX="033"

  if [ -n "${2}" ]; then
    # Color $2 with $1
    echo -e "\\${PREFIX}[${1}m${2}"
  elif [ -n "${1}" ]; then
    # Echo specified color
    echo -e "\\${PREFIX}[${1}m"
  else
    # Reset to default color
    echo -e "\\${PREFIX}[0m"
  fi
}
# Color escape sequences
function color() {
  local PREFIX="e"

  if [ -n "${2}" ]; then
    # Color $2 with $1
    echo -e "\\${PREFIX}[${1}m${2}"
  elif [ -n "${1}" ]; then
    # Echo specified color
    echo -e "\\${PREFIX}[${1}m"
  else
    # Reset to default color
    echo -e "\\${PREFIX}[0m"
  fi
}

## Prompt
function git_branch() {
  if [ -d .git ] ; then
    printf "$(np_color)($(np_color 0\;36)%s$(np_color)) " "$(git branch 2> /dev/null | awk '/\*/{print $2}')";
  fi
}

# export PS1="$grn[\t] \$(git_branch)$lbl\W$clr$ "
export PS1="\$(np_color 0\;32)[\t] \$(git_branch)\$(np_color 1\;34)\W\$(np_color)$ "

## Custom functions

# Print network information
function netinfo() {
  printf "$(color 0\;36)DATE$(color): %s\n" "$(date)"
  printf "$(color 0\;36)USER@HOSTNAME$(color): %s@%s\n" "$(whoami)" "$(hostname)"
  #printf "$(color 0\;36)LOCAL IP ADDR$(color): %s\n" "$()"
  printf "$(color 0\;36)PUBLIC IP ADDR$(color): %s\n" "$(curl -s ifconfig.me)"
}
