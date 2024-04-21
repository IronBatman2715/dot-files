#!/bin/bash
#
# Install dot files with user prompts for options and verification of install process.

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
      echo -e "\e[0;31mInvalid entry\e[0m: $INPUT"
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
    echo -e "  Creating empty \e[0;36m$SRC_PATH\e[0m"
    touch "$SRC_PATH"
  fi

  # If nothing exists at $SYMLINK_PATH, simply create symlink and return
  if [[ ! -e "$SYMLINK_PATH" ]]; then
    echo -e "  Creating symlink at \e[0;36m$SYMLINK_PATH\e[0m pointing to \e[0;36m$SRC_PATH\e[0m"
    ln -s "$SRC_PATH" "$SYMLINK_PATH"
    return
  fi

  local prompt="  Something already exists at \e[0;36m$SYMLINK_PATH\e[0m. Overwrite?"
  if [[ -L "$SYMLINK_PATH" ]]; then
    local symlink_real_path
    symlink_real_path="$(realpath "$SYMLINK_PATH")"

    if [[ "$symlink_real_path" == "$SRC_PATH" ]]; then
      echo -e "  \e[0;36m$SYMLINK_PATH\e[0m is already a symlink to \e[0;36m$SRC_PATH\e[0m. Skipping"
      return
    fi

    # Update prompt with new information
    prompt="  \e[0;36m$SYMLINK_PATH\e[0m is already a symlink BUT it points to a different location (\e[0;36m$symlink_real_path\e[0m). Overwrite?"
  fi
  readonly prompt

  if util::yn_prompt "$prompt" 0; then
    echo -e "    Overwriting \e[0;36m$SYMLINK_PATH\e[0m"
    rm -rf "$SYMLINK_PATH"

    echo -e "    Creating symlink at \e[0;36m$SYMLINK_PATH\e[0m pointing to \e[0;36m$SRC_PATH\e[0m"
    ln -s "$SRC_PATH" "$SYMLINK_PATH"
  else
    echo -e "    Skipped install of \e[0;36m$1\e[0m"
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
  echo -e "Identified this as a \e[0;36m$OSTYPE_DESCRIPTOR\e[0m system."

  if [[ "$OSTYPE" == "msys" ]]; then
    if ! util::yn_prompt "Confirm that you have read \e[0;36mREADME\e[0m installation notes for $OSTYPE_DESCRIPTOR?"; then
      echo -e "  \e[0;31mExiting\e[0m due to unconfirmed setup"
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
      echo -e "Delete or rename \e[0;36m$TEMP_DIR\e[0m. As this program needs to create a temporary directory there."
      exit 1
    fi
  else
    mkdir "$TEMP_DIR"
  fi

  echo "Creating file symlinks"
  util::create_file_symlink "$PROJECT_DIR/.bash_aliases"        "$HOME/.bash_aliases"
  util::create_file_symlink "$PROJECT_DIR/.bash_profile"        "$HOME/.bash_profile"
  util::create_file_symlink "$PROJECT_DIR/.bash_program_setups" "$HOME/.bash_program_setups"
  util::create_file_symlink "$PROJECT_DIR/.bashrc"              "$HOME/.bashrc"
  util::create_file_symlink "$PROJECT_DIR/.vimrc"               "$HOME/.vimrc"

  echo "Generating other files"

  echo -e "  Generating .gitconfig (this will \e[0;33moverwrite\e[0m \e[0;36m$HOME/.gitconfig\e[0m if present)"
  local USERNAME
  read -rp $'    Enter GitHub username (leave blank to skip \e[0;36m.gitconfig\e[0m): ' USERNAME
  if [[ "$USERNAME" != "" || $DEBUG == 1 ]]; then
    # Verify if 'jq' is available
    local USE_JQ=0
    if command -v jq &> /dev/null; then
      if [[ $DEBUG == 1 ]]; then
        echo "    [DEBUG] Using 'jq'"
      fi
    else      
      if ! util::yn_prompt "    Could not find 'jq' (https://github.com/jqlang/jq) installed on your system. This is needed for \e[0;33mstable\e[0m JSON parsing.\n\tProceed with rough JSON parsing using grep?"; then
        exit 1
      fi
      USE_JQ=1
      if [[ $DEBUG == 1 ]]; then
        echo "    [DEBUG] Using rough JSON parsers"
      fi
    fi
    readonly USE_JQ

    # --- Start parsing values for .gitconfig --- #

    # Fetch github user data
    local -r GH_RES_JSON="$TEMP_DIR/gh_api_res.json"
    if [[ ! -e "$GH_RES_JSON" ]]; then
      if [[ $DEBUG == 1 && "$USERNAME" == "" ]]; then
        echo "[DEBUG] Must enter GitHub username at least one time to test further"; exit 1
      fi

      local -r GH_REQUEST_URL="https://api.github.com/users/$USERNAME"
      echo -e "    Sending request to \e[0;36m$GH_REQUEST_URL\e[0m"
      if command -v curl &> /dev/null; then
        if [[ $DEBUG == 1 ]]; then
          echo "    [DEBUG] Using 'curl'"
        fi
        curl -so "$GH_RES_JSON" "$GH_REQUEST_URL"
      elif command -v wget &> /dev/null; then
        if [[ $DEBUG == 1 ]]; then
          echo "    [DEBUG] Using 'wget'"
        fi
        wget -qO "$GH_RES_JSON" "$GH_REQUEST_URL"
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

    # Prompt and handle Git-LFS option
    local DO_GIT_LFS=1
    if util::yn_prompt "    Enable Git-LFS in \e[0;36m$HOME/.gitconfig\e[0m? (still need to install on your system)" 0; then
      if [[ $DEBUG == 1 ]]; then
        echo "    [DEBUG] Enabling Git-LFS"
      fi

      DO_GIT_LFS=0
    fi
    readonly DO_GIT_LFS

    # Set auto-crlf based on $OSTYPE
    local AUTO_CRLF=''
    case "$OSTYPE" in
      "linux-gnu") AUTO_CRLF='input';;
      "msys")      AUTO_CRLF='true';;
    esac
    echo -e "    Setting \e[0;36mcore.autocrlf\e[0m to \e[0;36m$AUTO_CRLF\e[0m since this is a \e[0;36m$OSTYPE_DESCRIPTOR\e[0m system. "
    readonly AUTO_CRLF

    # Prompt and handle git text editor (used for commit messages and such)
    local GIT_EDITOR
    read -rp $'    Enter Git text editor executable (default: \e[0;36mvim\e[0m): ' GIT_EDITOR
    if [[ "$GIT_EDITOR" == "" ]]; then
      if [[ $DEBUG == 1 ]]; then
        echo "    [DEBUG] Setting \$GIT_EDITOR to default value"
      fi
      GIT_EDITOR="vim"
    fi
    readonly GIT_EDITOR

    # --- End parsing values for .gitconfig --- #

    # Generate .gitconfig in temp directory and parse in values
    echo -e "    Generating \e[0;36m$HOME/.gitconfig\e[0m based on \e[0;36m$PROJECT_DIR/template.gitconfig\e[0m"
    local -r TEMP_GIT_CONFIG="$TEMP_DIR/.gitconfig"
    cp "$PROJECT_DIR/template.gitconfig" "$TEMP_GIT_CONFIG"
    if [[ $DO_GIT_LFS == 0 ]]; then
      local -r GIT_LFS_STR=$'[filter "lfs"]\n  smudge = git-lfs smudge -- %f\n  process = git-lfs filter-process\n  required = true\n  clean = git-lfs clean -- %f'
      echo "$GIT_LFS_STR" >> "$TEMP_GIT_CONFIG"
    fi
    sed -i "s/##USERNAME##/$USERNAME/g"     "$TEMP_GIT_CONFIG"
    sed -i "s/##USER_ID##/$USER_ID/g"       "$TEMP_GIT_CONFIG"
    sed -i "s/##AUTO_CRLF##/$AUTO_CRLF/g"   "$TEMP_GIT_CONFIG"
    sed -i "s/##GIT_EDITOR##/$GIT_EDITOR/g" "$TEMP_GIT_CONFIG"

    if [[ $DEBUG == 1 ]]; then
      echo -e "    [DEBUG] Skipping copy of \e[0;36m.gitconfig\e[0m to home directory"
    else
      cp "$TEMP_GIT_CONFIG" "$HOME/.gitconfig"
    fi
  else
    echo -e "    Skipping \e[0;36m.gitconfig\e[0m"
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
