#!/bin/bash
#
# Install dot files with user prompts for options and verification of install process.

set -e # exit immediately on error

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
function util::color() {
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

########################################
# Alias for `util::color` with '0;34' as the color.
# Globals:
# Arguments:
#   1: String to be colored.
# Outputs:
# Returns:
#   See `util::color`.
########################################
function util::color_url() {
  util::color '0;34' "$1"
}

########################################
# Alias for `util::color` with '0;36' as the color.
# Globals:
# Arguments:
#   1: String to be colored.
# Outputs:
# Returns:
#   See `util::color`.
########################################
function util::color_path() {
  util::color '0;36' "$1"
}

########################################
# Alias for `util::color` with '0;33' as the color.
# Globals:
# Arguments:
#   1: String to be colored.
# Outputs:
# Returns:
#   See `util::color`.
########################################
function util::color_warn() {
  util::color '0;33' "$1"
}

########################################
# Alias for `util::color` with '0;31' as the color.
# Globals:
# Arguments:
#   1: String to be colored.
# Outputs:
# Returns:
#   See `util::color`.
########################################
function util::color_error() {
  util::color '0;31' "$1"
}

########################################
# Prompt user via stdout/stdin with a yes or no question.
# Globals:
# Arguments:
#   1: prompt string (Ex: "Do you want to continue?").
#   2: [OPTIONAL] default answer to question. 0 for yes, 1 for no. If not set, defaults to no.
# Outputs:
#   Writes prompt to stdout
# Returns:
#   0 for yes, 1 for no
########################################
function util::yn_prompt() {
  local yn_brackets="["  
  case $2 in
    0)  yn_brackets+="Y/n";;
    1)  ;&
    "") yn_brackets+="y/N";;
    *)
      echo "Could not match \"$2\" to a valid option"
      exit 1;;
  esac
  yn_brackets+="]: "
  readonly yn_brackets

  read -rp "$(echo -e "$1 $yn_brackets")" INPUT

  while :; do
    if [[ ${INPUT,,} == "y" || ($INPUT == "" && $2 == 0) ]]; then
      return 0
    elif [[ ${INPUT,,} == "n" || ($INPUT == "" && $2 != 0) ]]; then
      return 1
    else
      echo -e "$(util::color_error 'Invalid entry'): $INPUT"
      read -rp "$(echo -e "Try again $yn_brackets")" INPUT
    fi
  done
}

########################################
# Create a symlink for a file.
# Globals:
#   On Git Bash for Windows, REQUIRES "MSYS=winsymlinks:nativestrict".
# Arguments:
#   1: source file path.
#   2: symlink file path.
# Outputs:
#   If source path does not point to a file, create empty file there.
#   If symlink path doesn't point to anything, simply create symlink there.
#   If symlink path is already occupied, prompt user in stdout whether to overwrite or do nothing.
#   If symlink path already points to source path, do nothing.
# Returns:
########################################
function util::create_file_symlink() {
  local -r SRC_PATH="$1"
  local -r SYMLINK_PATH="$2"

  if [[ ! -f "$SRC_PATH" ]]; then
    echo -e "  Creating empty $(util::color_path "$SRC_PATH")"
    touch "$SRC_PATH"
  fi

  # If nothing exists at $SYMLINK_PATH, simply create symlink and return
  if [[ ! -e "$SYMLINK_PATH" ]]; then
    echo -e "  Creating symlink at $(util::color_path "$SYMLINK_PATH") pointing to $(util::color_path "$SRC_PATH")"
    ln -s "$SRC_PATH" "$SYMLINK_PATH"
    return
  fi

  local prompt
  if [[ -L "$SYMLINK_PATH" ]]; then
    local symlink_real_path
    symlink_real_path="$(realpath "$SYMLINK_PATH")"

    if [[ "$symlink_real_path" == "$SRC_PATH" ]]; then
      echo -e "  $(util::color_path "$SYMLINK_PATH") is already a symlink to $(util::color_path "$SRC_PATH"). Skipping"
      return
    fi

    # Update prompt with new information
    prompt="  $(util::color_path "$SYMLINK_PATH") is already a symlink BUT it points to a different location ($(util::color_path "$symlink_real_path")). Overwrite?"
  else
    prompt="  Something already exists at $(util::color_path "$SYMLINK_PATH"). Overwrite?"
  fi
  readonly prompt

  if util::yn_prompt "$prompt" 0; then
    echo -e "    Overwriting $(util::color_path "$SYMLINK_PATH")"
    rm -rf "$SYMLINK_PATH"

    echo -e "    Creating symlink at $(util::color_path "$SYMLINK_PATH") pointing to $(util::color_path "$SRC_PATH")"
    ln -s "$SRC_PATH" "$SYMLINK_PATH"
  else
    echo -e "    Skipped install of $(util::color_path "$SRC_PATH")"
  fi
}

########################################
# Parse a JSON for the *number* value at a specifed key.
# Globals:
# Arguments:
#   1: JSON key to parse (Ex: "id").
#   2 OR stdin: JSON as text OR JSON file location (respectively) 
# Outputs:
# Returns:
#   Parsed number
########################################
function util::parse_json_num() {
  local -r VALUE_PATTERN="[0-9]+"
  local -r LINE_PATTERN="\"$1\":\s*${VALUE_PATTERN}\s*,?"

  case $# in
    1) PARSED_NUMBER=$(cat /dev/stdin | grep -oE "$LINE_PATTERN" | grep -oE "$VALUE_PATTERN");;
    2) PARSED_NUMBER=$(grep -oE "$LINE_PATTERN" "$2" | grep -oE "$VALUE_PATTERN");;
    *) echo "Must enter a key to parse and then either pipe in the JSON or enter the JSON file name!"; exit 1;;
  esac

  if [[ "$PARSED_NUMBER" =~ ^$VALUE_PATTERN$ ]]; then
    echo "$PARSED_NUMBER"
  else
    echo "Parsed value is NOT a number!"; exit 1
  fi
}

########################################
# Parse a JSON for the *string* value at a specifed key.
# Globals:
# Arguments:
#   1: JSON key to parse (Ex: "id").
#   2 OR stdin: JSON as text OR JSON file location (respectively) 
# Outputs:
# Returns:
#   Parsed string
########################################
function util::parse_json_str() {
  local -r VALUE_PATTERN="[A-Za-z0-9_-]+"
  local -r LINE_PATTERN="\"$1\":\s*\"${VALUE_PATTERN}\"\s*,?"

  case $# in
    1) PARSED_STRING=$(cat /dev/stdin | grep -oE "$LINE_PATTERN" | grep -oE "$VALUE_PATTERN" | tail -1);;
    2) PARSED_STRING=$(grep -oE "$LINE_PATTERN" "$2" | grep -oE "$VALUE_PATTERN" | tail -1);;
    *) echo "Must enter a key to parse and then either pipe in the JSON or enter the JSON file name!"; exit 1;;
  esac

  if [[ "$PARSED_STRING" =~ ^$VALUE_PATTERN$ ]]; then
    echo "$PARSED_STRING"
  else
    echo "Parsed value is NOT a string!"; exit 1
  fi
}

function main() {
  # Set DEBUG=1 to run in debug mode (i.e. "DEBUG=1 ./install.bash")
  if [[ $DEBUG != 1 ]]; then
    DEBUG=0 # Normal operation
  fi
  if [[ $DEBUG == 1 ]]; then
    echo "[DEBUG] Debug mode active!"
  fi

  local OSTYPE_DESCRIPTOR=''
  case "$OSTYPE" in
    "linux-gnu")
      OSTYPE_DESCRIPTOR="GNU Linux";;
    "msys")
      OSTYPE_DESCRIPTOR="Git Bash for Windows (MinGW)";;
    *)
      # Unknown OS
      echo "Could not match \"$OSTYPE\" to a supported system"
      exit 1;;
  esac
  readonly OSTYPE_DESCRIPTOR
  echo -e "Identified this as a $(util::color_path "$OSTYPE_DESCRIPTOR") system."
  
  # Feb 5 2025
  # At time of writing, starship is available via standard package management on all platforms I use except
  #   Debian 12 or older (this of course means corresponding Ubuntu derivatives as well).
  #   For now, manual management via their install script will suffice. Debian 13 should not be too far out.
  # 
  # TODO: move older systems to package manager install rather than manual script when applicable
  if command -v starship &> /dev/null; then
    if [[ $DEBUG == 1 ]]; then
      echo "    [DEBUG] Verified 'starship' command is available"
    fi
  else      
    echo -e "$(util::color_error Error): Could not find 'starship' ($(util::color_url https://starship.rs/)) installed on your system. This is needed for the shell prompt."
    exit 1
  fi

  if [[ "$OSTYPE" == "msys" ]]; then
    if ! util::yn_prompt "Confirm that you have read $(util::color_path README) installation notes for $OSTYPE_DESCRIPTOR?"; then
      echo -e "  $(util::color_error Exiting) due to unconfirmed setup"
      exit 1
    fi

    if [[ $DEBUG == 1 ]]; then
      echo "[DEBUG] Setting MSYS environment variable so symlinks work as expected."
    fi
    export MSYS=winsymlinks:nativestrict
  fi
  echo

  local -r PROJECT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
  local -r TEMP_DIR="$PROJECT_DIR/.temp"
  if [[ -e "$TEMP_DIR" ]]; then
    if [[ $DEBUG == 0 ]]; then
      echo -e "Delete or rename $(util::color_path "$TEMP_DIR"). This program needs to create a temporary directory there."
      exit 1
    fi
  else
    mkdir "$TEMP_DIR"
  fi

  local HOME_DIR="$HOME"
  if [[ $DEBUG == 1 ]]; then
    HOME_DIR="$TEMP_DIR/dummy_home"
    if [[ ! -e "$HOME_DIR" ]]; then
      mkdir "$HOME_DIR"
    fi
  fi
  readonly HOME_DIR

  # assume default XDG config home for installer
  local -r I_XDG_CONFIG_HOME="$HOME_DIR/.config"

  # --- Start XDG checks --- #
  if [[ ! -e "$I_XDG_CONFIG_HOME" ]]; then
    echo -e "Creating $(util::color_path "$I_XDG_CONFIG_HOME") directory"
    mkdir "$I_XDG_CONFIG_HOME"
  fi
  if [[ ! -e "$I_XDG_CONFIG_HOME/bash" ]]; then
    echo -e "Creating $(util::color_path "$I_XDG_CONFIG_HOME/bash") directory"
    mkdir "$I_XDG_CONFIG_HOME/bash"
  fi
  if [[ -e "$HOME_DIR/.vimrc" ]]; then
    if ! util::yn_prompt "Need to delete $(util::color_path "$HOME_DIR/.vimrc"). Otherwise, "$I_XDG_CONFIG_HOME/vim/vimrc" will be ignored.\n\tDelete $(util::color_path "$HOME_DIR/.vimrc")?"; then
        exit 1
    fi
    rm "$HOME_DIR/.vimrc"
  fi
  if [[ -e "$HOME_DIR/.vim" ]]; then
    if ! util::yn_prompt "Need to delete $(util::color_path "$HOME_DIR/.vim"). Otherwise, "$I_XDG_CONFIG_HOME/vim/vimrc" will be ignored.\n\tDelete $(util::color_path "$HOME_DIR/.vim")?"; then
        exit 1
    fi
    rm -r "$HOME_DIR/.vim"
  fi
  if [[ ! -e "$I_XDG_CONFIG_HOME/vim" ]]; then
    echo -e "Creating $(util::color_path "$I_XDG_CONFIG_HOME/vim") directory"
    mkdir "$I_XDG_CONFIG_HOME/vim"
  fi
  # --- End XDG checks --- #

  if [[ ! -f "$PROJECT_DIR/bash/system" ]]; then
    echo -e "Creating empty $(util::color_path "$PROJECT_DIR/bash/system") from template"
    cp "$PROJECT_DIR/templates/bash/system" "$PROJECT_DIR/bash/system"
  else
    echo -e "Leaving pre-existing $(util::color_path "$PROJECT_DIR/bash/system")"
  fi

  echo "Creating file symlinks"
  util::create_file_symlink "$PROJECT_DIR/.profile"      "$HOME_DIR/.profile"
  util::create_file_symlink "$PROJECT_DIR/.bashrc"       "$HOME_DIR/.bashrc"
  util::create_file_symlink "$PROJECT_DIR/bash/aliases"  "$I_XDG_CONFIG_HOME/bash/aliases"
  util::create_file_symlink "$PROJECT_DIR/bash/system"   "$I_XDG_CONFIG_HOME/bash/system"
  util::create_file_symlink "$PROJECT_DIR/vim/vimrc"     "$I_XDG_CONFIG_HOME/vim/vimrc"
  util::create_file_symlink "$PROJECT_DIR/starship.toml" "$I_XDG_CONFIG_HOME/starship.toml"

  echo "Generating other files"

  echo -e "  Generating Git config (this will (if present) $(util::color_warn delete) $(util::color_path "$HOME_DIR/.gitconfig") *and* $(util::color_warn overwrite) $(util::color_path "$I_XDG_CONFIG_HOME/git/config"))"
  local USERNAME
  read -rp "    Enter GitHub username (leave blank to skip generating Git config): " USERNAME
  if [[ "$USERNAME" != "" || $DEBUG == 1 ]]; then
    # Verify if 'jq' is available
    local USE_JQ=0
    if command -v jq &> /dev/null; then
      if [[ $DEBUG == 1 ]]; then
        echo "    [DEBUG] Using 'jq'"
      fi
    else      
      if ! util::yn_prompt "    Could not find 'jq' ($(util::color_url https://github.com/jqlang/jq)) installed on your system. This is needed for $(util::color_warn stable) JSON parsing.\n\tProceed with rough JSON parsing using grep?"; then
        exit 1
      fi
      USE_JQ=1
      if [[ $DEBUG == 1 ]]; then
        echo "    [DEBUG] Using rough JSON parsers"
      fi
    fi
    readonly USE_JQ

    # --- Start parsing values for Git config --- #

    # Fetch github user data
    local -r GH_RES_JSON="$TEMP_DIR/gh_api_res.json"
    if [[ ! -e "$GH_RES_JSON" ]]; then
      if [[ $DEBUG == 1 && "$USERNAME" == "" ]]; then
        echo "[DEBUG] Must enter GitHub username at least one time to test further"; exit 1
      fi

      # https://docs.github.com/en/rest/users/users?apiVersion=2022-11-28
      local -r GH_REQUEST_URL="https://api.github.com/users/$USERNAME"
      echo -e "    Sending request to $(util::color_url "$GH_REQUEST_URL")"
      if command -v curl &> /dev/null; then
        if [[ $DEBUG == 1 ]]; then
          echo "    [DEBUG] Using 'curl'"
        fi
        curl -so "$GH_RES_JSON" -H "Accept: application/vnd.github+json" -H "X-GitHub-Api-Version: 2022-11-28" "$GH_REQUEST_URL"
      elif command -v wget &> /dev/null; then
        if [[ $DEBUG == 1 ]]; then
          echo "    [DEBUG] Using 'wget'"
        fi
        wget -qO "$GH_RES_JSON" --header "Accept: application/vnd.github+json" --header "X-GitHub-Api-Version: 2022-11-28" "$GH_REQUEST_URL"
      else
        echo "Could not execute either 'curl' or 'wget' to fetch GitHub data. Please install one of the two."
        exit 1
      fi
    fi

    # Verify username matches github user data
    local VERIFY_USERNAME
    if [[ $USE_JQ == 0 ]]; then
      VERIFY_USERNAME=$(jq -r '.login' "$GH_RES_JSON")
    else
      VERIFY_USERNAME=$(util::parse_json_str login "$GH_RES_JSON")
    fi
    readonly VERIFY_USERNAME
    if [[ $DEBUG == 1 && "$USERNAME" == "" ]]; then
      echo "    [DEBUG] Setting \$USERNAME to cached value"
      USERNAME="$VERIFY_USERNAME"
    fi
    readonly USERNAME
    if [[ "$USERNAME" != "$VERIFY_USERNAME" ]]; then
      echo "Received mismatched username data. (Username requested: $USERNAME) (Username received: $VERIFY_USERNAME)"
      exit 1
    fi

    # Verified, now parse required data
    local USER_ID
    if [[ $USE_JQ == 0 ]]; then
      USER_ID=$(jq '.id' "$GH_RES_JSON")
    else
      USER_ID=$(util::parse_json_num id "$GH_RES_JSON")
    fi
    readonly USER_ID

    # Set Git-LFS settings based on if it is installed
    local DO_GIT_LFS=1
    set +e # temporarily disable
    git lfs > /dev/null 2>&1
    local -r GIT_LFS_INSTALL_STATUS="$?"
    set -e
    case "$GIT_LFS_INSTALL_STATUS" in
      0) DO_GIT_LFS=0;;
      *)
         if util::yn_prompt "    Git-LFS ($(util::color_url https://git-lfs.com/)) is NOT installed. Enable anyway?" 1; then
           DO_GIT_LFS=0
         fi
    esac
    if [[ $DO_GIT_LFS == 0 ]]; then
      echo "    Setting $(util::color_path 'filter "lfs"') for Git-LFS"
    fi
    readonly DO_GIT_LFS

    # Set auto-crlf based on $OSTYPE
    local AUTO_CRLF=''
    case "$OSTYPE" in
      "linux-gnu") AUTO_CRLF='input';;
      "msys")      AUTO_CRLF='true';;
    esac
    echo -e "    Setting $(util::color_path core.autocrlf) to $(util::color_path $AUTO_CRLF) since this is a $(util::color_path "$OSTYPE_DESCRIPTOR") system. "
    readonly AUTO_CRLF

    # Prompt and handle git text editor (used for commit messages and such)
    local GIT_EDITOR
    read -rp "    Enter Git text editor executable (default: $(util::color_path vim)): " GIT_EDITOR
    if [[ "$GIT_EDITOR" == "" ]]; then
      if [[ $DEBUG == 1 ]]; then
        echo "    [DEBUG] Setting \$GIT_EDITOR to default value"
      fi
      GIT_EDITOR="vim"
    fi
    readonly GIT_EDITOR

    # --- End parsing values for Git config --- #

    # Generate Git config in temp directory and parse in values
    echo -e "    Generating $(util::color_path "$I_XDG_CONFIG_HOME/git/config") from $(util::color_path "$PROJECT_DIR/templates/git/config")"
    local -r TEMP_GIT_CONFIG="$TEMP_DIR/gitconfig"
    cp "$PROJECT_DIR/templates/git/config" "$TEMP_GIT_CONFIG"
    if [[ $DO_GIT_LFS == 0 ]]; then
      local -r GIT_LFS_STR=$'[filter "lfs"]\n  smudge = git-lfs smudge -- %f\n  process = git-lfs filter-process\n  required = true\n  clean = git-lfs clean -- %f'
      echo "$GIT_LFS_STR" >> "$TEMP_GIT_CONFIG"
    fi
    sed -i "s/##USERNAME##/$USERNAME/g"     "$TEMP_GIT_CONFIG"
    sed -i "s/##USER_ID##/$USER_ID/g"       "$TEMP_GIT_CONFIG"
    sed -i "s/##AUTO_CRLF##/$AUTO_CRLF/g"   "$TEMP_GIT_CONFIG"
    sed -i "s/##GIT_EDITOR##/$GIT_EDITOR/g" "$TEMP_GIT_CONFIG"

    if [[ -f "$HOME_DIR/.gitconfig" ]]; then
      echo -e "    Deleting $(util::color_path "$HOME_DIR/.gitconfig") in favor of $(util::color_path "$I_XDG_CONFIG_HOME/git/config")"
      rm "$HOME_DIR/.gitconfig"
    fi
    if [[ $DEBUG == 1 ]]; then
      echo -e "    [DEBUG] Copying $(util::color_path "$TEMP_GIT_CONFIG") to $(util::color_path "$I_XDG_CONFIG_HOME/git/config")"
    fi
    mkdir -p "$I_XDG_CONFIG_HOME/git"
    cp "$TEMP_GIT_CONFIG" "$I_XDG_CONFIG_HOME/git/config"
  else
    echo -e "    Skipping $(util::color_path "$I_XDG_CONFIG_HOME/git/config")"
  fi


  echo
  if [[ $DEBUG == 1 ]]; then
    echo "[DEBUG] Skipping cleaning up temporary files"
  else
    echo "Cleaning up temporary files"
    rm -r "$TEMP_DIR"
  fi

  echo "Install complete!"
}

main "$@"
