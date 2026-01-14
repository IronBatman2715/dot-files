#!/usr/bin/sh

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/bin" ] ; then
    PATH="$HOME/bin:$PATH"
fi

# Load XDG spec
. "$HOME/.config/env/xdg.sh"

# set PATH so it includes user's private bin if it exists
if [ -d "$XDG_BIN_HOME" ] ; then
    PATH="$XDG_BIN_HOME:$PATH"
fi

export EDITOR="vim"
