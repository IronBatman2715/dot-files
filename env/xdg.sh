#!/bin/sh

# https://specifications.freedesktop.org/basedir-spec/latest/
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"
export XDG_BIN_HOME="$HOME/.local/bin" # not an official variable, but used by some programs

## Common programs

# bash
export HISTFILE="$XDG_STATE_HOME/bash/history"

# starship
export STARSHIP_CONFIG="$XDG_CONFIG_HOME/starship.toml"
export STARSHIP_CACHE="$XDG_CACHE_HOME/starship"

# vim: required for vim <9.1.0327
export GVIMINIT='let $MYGVIMRC = !has("nvim") ? "$XDG_CONFIG_HOME/vim/gvimrc" : "$XDG_CONFIG_HOME/nvim/init.gvim" | so $MYGVIMRC'
export VIMINIT='let $MYVIMRC = !has("nvim") ? "$XDG_CONFIG_HOME/vim/vimrc" : "$XDG_CONFIG_HOME/nvim/init.vim" | so $MYVIMRC'

# wget
alias wget='wget --hsts-file=$XDG_CACHE_HOME/wget-hsts'
export WGETRC="$XDG_CONFIG_HOME/wgetrc"

## Development programs

export DOCKER_CONFIG="$XDG_CONFIG_HOME/docker"
export PYTHON_HISTORY="$XDG_STATE_HOME/python_history"

# node/npm
export NODE_REPL_HISTORY="$XDG_DATA_HOME/node_repl_history"
export NPM_CONFIG_USERCONFIG="$XDG_CONFIG_HOME/npm/npmrc"
# node/npm end

# pnpm
export PNPM_HOME="$XDG_DATA_HOME/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

# rust
export RUSTUP_HOME="$XDG_DATA_HOME/rustup"
export CARGO_HOME="$XDG_DATA_HOME/cargo"
if [ -e "$CARGO_HOME/env" ]; then . "$CARGO_HOME/env"; fi
# rust end

# juliaup
export JULIA_DEPOT_PATH="$XDG_DATA_HOME/julia:$JULIA_DEPOT_PATH"
export JULIAUP_DEPOT_PATH="$XDG_DATA_HOME/julia"

# TODO: not a spec, manually moved directory and edited this block
case ":$PATH:" in
  *":$XDG_DATA_HOME/juliaup/bin:"*) ;;
  *) export PATH="$XDG_DATA_HOME/juliaup/bin${PATH:+:${PATH}}" ;;
esac
# juliaup end
