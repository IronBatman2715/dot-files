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

## Aliases

# Run aliases file if present
[[ -f "$XDG_CONFIG_HOME/bash/aliases" ]] && . "$XDG_CONFIG_HOME/bash/aliases"

# Some XDG fixes require shell specific methods
[[ -f "$XDG_CONFIG_HOME/bash/xdg" ]] && . "$XDG_CONFIG_HOME/bash/xdg"

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

function loadenv() {
  # Default values
  local -r env_file_default=".env"

  # Usage information
  local -r usage="Usage: loadenv [OPTIONS] [PATH]

Load environment variables from a file into the current shell or a subshell.

Options:
  -h, --help       Show this help message
  -e, --execute COMMAND
                   Execute COMMAND in a subshell with the env file loaded.
                   The subshell is created and exited automatically.

Arguments:
  PATH         Path to the file to load (default: '$env_file_default')

Notes:
  - Variables are exported automatically (no need for 'export' in .env)
  - set -a is temporarily enabled only if needed"

  # Parse arguments
  local env_file=""
  local execute=""
  while [[ $# -gt 0 ]]; do
    case $1 in
      -h|--help)
        echo "$usage"
        return 0
        ;;
      -e|--execute)
        execute="$2"
        shift
        ;;
      -*)
        echo -e "$(_color '0;31' Error): Unknown option $1" >&2
        echo "$usage" >&2
        return 1
        ;;
      *)
        if [[ $env_file == "" ]]; then
          env_file="$1"
        else
          echo -e "$(_color '0;31' Error): Too many arguments $(_color '0;33' "$1")" >&2
          echo "$usage" >&2
          return 1
        fi
        ;;
    esac
    shift
  done

  # Set default(s) if not provided
  env_file="${env_file:-$env_file_default}"

  readonly env_file
  readonly execute
  # Done parsing inputs. Run actual logic

  if [[ "$OSTYPE" != "linux-gnu" ]]; then
    echo -e "$(_color '0;33' Warning): This has not been tested on your system" >&2
  fi

  if [ ! -f "$env_file" ]; then
    echo -e "$(_color '0;31' Error): File $(_color '0;36' "$env_file") not found" >&2
    return 1
  fi

  # Execute mode: create subshell and load env and then run command inside it
  if [[ $execute != "" ]]; then
    bash -ac "
      source '$env_file'
      echo -e 'Loaded $(_color '0;36' "$env_file")'
      $execute
    "
    return $?
  fi

  # Normal mode: load env in current shell

  local set_a_was_on=0
  # Check if set -a is already enabled
  if [[ $- == *a* ]]; then
    set_a_was_on=1
  else
    set -a
  fi
  readonly set_a_was_on

  # Source the env file
  source "$env_file"
  
  # Disable set -a only if it wasn't enabled before
  if [ $set_a_was_on -eq 0 ]; then
    set +a
  fi

  echo -e "Loaded $(_color '0;36' "$env_file")"
}

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
[[ -f "$XDG_CONFIG_HOME/bash/system" ]] && . "$XDG_CONFIG_HOME/bash/system"
