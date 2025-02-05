#!/bin/bash

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

########################################
# Color string.
#
# Some ANSI color escape codesAttribute codes:
# 0=none 1=bold 4=underscore 5=blink 7=reverse 8=concealed
# Text color codes:
# 30=black 31=red 32=green 33=yellow 34=blue 35=magenta 36=cyan 37=white
# Background color codes:
# 40=black 41=red 42=green 43=yellow 44=blue 45=magenta 46=cyan 47=white
#
# Globals:
# Arguments:
#   1: [OPTIONAL] ANSI color escape code. Defaults to unset color modifications.
#   2: [OPTIONAL] String to be colored.
# Outputs:
# Returns:
#   The color code or, if supplied, the string colored by said color code.
########################################
function _color() {
  case $# in
    2)
      # Color $2 with $1
      printf "\e[%sm%s\e[0m" "$1" "$2"
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

# https://github.com/starship/starship
eval "$(starship init bash)"

## Custom functions

# Print network information
function netinfo() {
  local output=''

  output+="$(_color '0;36' 'DATE'): $(date)"
  output+="\n$(_color '0;36' 'USER@HOSTNAME'): $(whoami)@$(hostname)"

  local local_ip_addr=''
  local router_local_ip_addr=''
  case "$OSTYPE" in
    "linux-gnu")
      local local_ip_info
      local_ip_info="$(ip route get 1.1.1.1)"

      local_ip_addr="$(echo "$local_ip_info" | head -1 | cut -f7 -d' ')"
      router_local_ip_addr="$(echo "$local_ip_info" | head -1 | cut -f3 -d' ')"
      ;;
    "msys")
      # Bash for Windows (MinGW)
      local local_ip_info
      local_ip_info="$(ipconfig)"

      local_ip_addr="$(echo "$local_ip_info" | grep 'IPv4 Address' | awk '{print $NF}')"
      router_local_ip_addr="$(echo "$local_ip_info" | grep -A 1 'Default Gateway' | tail -n 1 | awk '{print $1}')"
      ;;
    *)
      # Unknown OS
      echo "Could not match $OSTYPE"
      exit 1
      ;;
  esac

  output+="\n$(_color '0;36' 'LOCAL IP ADDR'): $local_ip_addr"
  output+="\n$(_color '0;36' 'ROUTER LOCAL IP ADDR'): $router_local_ip_addr"
  output+="\n$(_color '0;36' 'PUBLIC IP ADDR'): $(curl -s ipinfo.io/ip)"

  echo -e "$output"
}

# System specific setups/scripts.
# 
# WILL NEED TO MOVE SETUPS THERE MANUALLY AS PROGRAMS TYPICALLY WRITE HERE OR TO .bash_profile
if [ -f ~/.bash_system ]; then
  . ~/.bash_system
fi
