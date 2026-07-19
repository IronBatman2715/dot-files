#!/usr/bin/bash

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

# Add helpers/custom tools
# MUST run before other custom files, as they can use helpers defined here
[[ -f "$XDG_CONFIG_HOME/bash/util" ]] && . "$XDG_CONFIG_HOME/bash/util"

# Run aliases file if present
[[ -f "$XDG_CONFIG_HOME/bash/aliases" ]] && . "$XDG_CONFIG_HOME/bash/aliases"

# Some XDG fixes require shell specific methods
[[ -f "$XDG_CONFIG_HOME/bash/xdg" ]] && . "$XDG_CONFIG_HOME/bash/xdg"


## Prompt

# https://github.com/starship/starship
eval "$(starship init bash)"

# System specific setups/scripts.
[[ -f "$XDG_CONFIG_HOME/bash/system" ]] && . "$XDG_CONFIG_HOME/bash/system"
