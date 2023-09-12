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


function _build_prompt() {
  local exit_code="$?"

  # Bash prompt Non-printing color escape sequences
  function _np_color() {
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
  # Print git branch if current directory is a git repository
  function _git_branch() {
    if [ -d .git ] ; then
      printf "$(_np_color)($(_np_color '0;36')%s$(_np_color)) " "$(__git_ps1 '%s')"
    fi
  }

  function _display_status_code() {
    if [[ $exit_code == 0 ]] ; then
      # Last command was successful. Normal and green
      printf "$(_np_color '0;32')"
    else
      # Last command FAILED. Bold and red
      printf "$(_np_color '1;31')"
    fi
  }
  
  PS1="$(_display_status_code)[\t] $(_git_branch)$(_np_color '37;44')\u@\H$(_np_color) $(_np_color '1;34')\W$(_np_color)\$ "
}

PROMPT_COMMAND=_build_prompt

## Custom functions

# Print network information
function netinfo() {
  local output=''

  output+="$(color '0;36')DATE$(color): $(date)\n"
  output+="$(color '0;36')USER@HOSTNAME$(color): $(whoami)@$(hostname)\n"

  local local_ip_addr=''
  local router_local_ip_addr=''
  case "$OSTYPE" in
    "linux-gnu")
      local local_ip_info="$(ip route get 1.1.1.1)"

      local_ip_addr="$(echo "$local_ip_info" | head -1 | cut -f7 -d' ')"
      router_local_ip_addr="$(echo "$local_ip_info" | head -1 | cut -f3 -d' ')"
      ;;
    "msys")
      # Bash for Windows (MinGW)
      local local_ip_info="$(ipconfig)"

      local_ip_addr="$(echo "$local_ip_info" | grep 'IPv4 Address' | awk '{print $NF}')"
      router_local_ip_addr="$(echo "$local_ip_info" | grep -A 1 'Default Gateway' | tail -n 1 | awk '{print $1}')"
      ;;
    *)
      # Unknown OS
      echo "Could not match $OSTYPE"
      exit 1
      ;;
  esac

  output+="$(color '0;36')LOCAL IP ADDR$(color): $local_ip_addr\n"
  output+="$(color '0;36')ROUTER LOCAL IP ADDR$(color): $router_local_ip_addr\n"
  output+="$(color '0;36')PUBLIC IP ADDR$(color): $(curl -s ipinfo.io/ip)\n"

  printf "$output"
}

# Run setups for installed programs if present.
# 
# WILL NEED TO MOVE SETUPS THERE MANUALLY AS PROGRAMS TYPICALLY WRITE HERE OR TO .bash_profile
if [ -f ~/.bash_program_setups ]; then
  . ~/.bash_program_setups
fi
