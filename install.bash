#!/bin/bash

## HELPER FUNCTIONS ##

function yn_prompt() {
  # $1: prompt string
  # $2: default value. 0 for yes, 1 for no. If not set, defaults to no

  local yn_brackets="["
  if [[ $2 == 0 ]]; then
    yn_brackets+="Y/n"
  else
    yn_brackets+="y/N"
  fi
  yn_brackets+="]: "


  read -rp "$(echo -e "$1 $yn_brackets")" INPUT

  while :; do
    if [[ ${INPUT,,} == "y"|| ($INPUT == "" && $2 == 0) ]]; then
      return 0
    elif [[ ${INPUT,,} == "n"|| ($INPUT == "" && $2 != 0) ]]; then
      return 1
    else
      echo -e "\e[0;31mInvalid entry\e[0m: $INPUT"
      read -rp "$(echo -e "Try again $yn_brackets")" INPUT
    fi
  done
}

function create_file_symlink() {
  # $1 = source file path
  # $2 = symlink file path

  local src_path="$1"
  local symlink_path="$2"

  if [[ ! -f "$src_path" ]]; then
    echo -e "  Creating empty \e[0;36m$src_path\e[0m"
    touch "$src_path"
  fi

  # If nothing exists at $symlink_path, simply create symlink and return
  if [[ ! -e "$symlink_path" ]]; then
    echo -e "  Creating symlink at \e[0;36m$symlink_path\e[0m pointing to \e[0;36m$src_path\e[0m"
    ln -s "$src_path" "$symlink_path"
    return
  fi

  local prompt="  Something already exists at \e[0;36m$symlink_path\e[0m. Overwrite?"
  if [[ -L "$symlink_path" ]]; then
    local symlink_real_path="$(realpath "$symlink_path")"
    if [[ "$symlink_real_path" == "$src_path" ]]; then
      echo -e "  \e[0;36m$symlink_path\e[0m is already a symlink to \e[0;36m$src_path\e[0m. Skipping"
      return
    fi

    # Update prompt with new information
    prompt="  \e[0;36m$symlink_path\e[0m is already a symlink BUT it points to a different location (\e[0;36m$symlink_real_path\e[0m). Overwrite?"
  fi

  if yn_prompt "$prompt" 0; then
    echo -e "    Overwriting \e[0;36m$symlink_path\e[0m"
    rm -rf "$symlink_path"

    echo -e "    Creating symlink at \e[0;36m$symlink_path\e[0m pointing to \e[0;36m$src_path\e[0m"
    ln -s "$src_path" "$symlink_path"
  else
    echo -e "    Skipped install of \e[0;36m$1\e[0m"
  fi
}

function parseJsonNum() {
  # $1 = JSON key to parse
  # $2 OR /dev/stdin = JSON as text OR JSON file location (respectively)

  local VALUE_PATTERN="[0-9]+"
  local LINE_PATTERN="\"$1\":\s*${VALUE_PATTERN}\s*,?"

  case $# in
    1)
      PARSED_NUMBER=$(cat /dev/stdin | grep -oE "$LINE_PATTERN" | grep -oE "$VALUE_PATTERN")
    ;;
    2)
      PARSED_NUMBER=$(grep -oE "$LINE_PATTERN" "$2" | grep -oE "$VALUE_PATTERN")
    ;;
    *)
      echo "Must enter a key to parse and then either pipe in the JSON or enter the JSON file name!"; exit 1
    ;;
  esac

  if [[ "$PARSED_NUMBER" =~ ^$VALUE_PATTERN$ ]]; then
    echo "$PARSED_NUMBER"
  else
    echo "Parsed value is NOT a number!"; exit 1
  fi
}

function parseJsonStr() {
  # $1 = JSON key to parse
  # $2 OR /dev/stdin = JSON as text OR JSON file location (respectively)

  local VALUE_PATTERN="[A-Za-z0-9_-]+"
  local LINE_PATTERN="\"$1\":\s*\"${VALUE_PATTERN}\"\s*,?"

  case $# in
    1)
      PARSED_STRING=$(cat /dev/stdin | grep -oE "$LINE_PATTERN" | grep -oE "$VALUE_PATTERN" | tail -1)
    ;;
    2)
      PARSED_STRING=$(grep -oE "$LINE_PATTERN" "$2" | grep -oE "$VALUE_PATTERN" | tail -1)
    ;;
    *)
      echo "Must enter a key to parse and then either pipe in the JSON or enter the JSON file name!"; exit 1
    ;;
  esac

  if [[ "$PARSED_STRING" =~ ^$VALUE_PATTERN$ ]]; then
    echo "$PARSED_STRING"
  else
    echo "Parsed value is NOT a string!"; exit 1
  fi
}

### MAIN ###

# Set DEBUG=1 to run in debug mode (i.e. "DEBUG=1 ./install.bash")

if [[ $DEBUG != 1 ]]; then
  DEBUG=0 # Normal operation
fi
if [[ $DEBUG == 1 ]]; then
  echo "[DEBUG] Debug mode active!"
fi

OS_TYPE_DESCRIPTOR=''
AUTO_CRLF=''
case "$OSTYPE" in
  "linux-gnu")
    OS_TYPE_DESCRIPTOR="GNU Linux"
    AUTO_CRLF='input'
    ;;
  "msys")
    OS_TYPE_DESCRIPTOR="Git Bash for Windows (MinGW)"
    AUTO_CRLF='true'
    ;;
  *)
    # Unknown OS
    echo "Could not match \"$OSTYPE\" to a supported system"
    exit 1
    ;;
esac
echo -e "Identified this as a \e[0;36m$OS_TYPE_DESCRIPTOR\e[0m system."

if [[ "$OSTYPE" == "msys" ]]; then
  if ! yn_prompt "Confirm that you have read \e[0;36mREADME\e[0m installation notes for $OS_TYPE_DESCRIPTOR?"; then
    echo -e "  \e[0;31mExiting\e[0m due to unconfirmed setup"
    exit 1
  fi

  if [[ $DEBUG == 1 ]]; then
    echo "[DEBUG] Setting MSYS environment variable so symlinks work as expected."
  fi
  export MSYS=winsymlinks:nativestrict
fi

projectDir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
tempDir="$projectDir/.temp"
if [[ -e "$tempDir" ]]; then
  if [[ $DEBUG == 0 ]]; then
    echo -e "Delete or rename \e[0;36$tempDir\e[0m]. As this program needs to create a temporary directory there."
    exit 1
  fi
else
  mkdir "$tempDir"
fi

echo "Creating file symlinks"
create_file_symlink "$projectDir/.bash_aliases"         "$HOME/.bash_aliases"
create_file_symlink "$projectDir/.bash_profile"         "$HOME/.bash_profile"
create_file_symlink "$projectDir/.bash_program_setups"  "$HOME/.bash_program_setups"
create_file_symlink "$projectDir/.bashrc"               "$HOME/.bashrc"
create_file_symlink "$projectDir/.vimrc"                "$HOME/.vimrc"

echo "Generating other files"

echo -e "  Generating .gitconfig (this will \e[0;33moverwrite\e[0m \e[0;36m$HOME/.gitconfig\e[0m if present)"
read -rp $'    Enter GitHub username (leave blank to skip \e[0;36m.gitconfig\e[0m): ' USERNAME
if [[ "$USERNAME" != "" || $DEBUG == 1 ]]; then

  # Fetch github user data
  if [[ ! -e "$tempDir/gh_api_res.json" ]]; then
    if [[ $DEBUG == 1 && "$USERNAME" == "" ]]; then
      echo "[DEBUG] Must enter GitHub username at least one time to test further"; exit 1
    fi

    echo -e "    Sending request to \e[0;36mhttps://api.github.com/users/$USERNAME\e[0m"
    if command -v curl &> /dev/null; then
      if [[ $DEBUG == 1 ]]; then
        echo "    [DEBUG] Using 'curl'"
      fi
      curl -so "$tempDir/gh_api_res.json" "https://api.github.com/users/$USERNAME"
    elif command -v wget &> /dev/null; then
      if [[ $DEBUG == 1 ]]; then
        echo "    [DEBUG] Using 'wget'"
      fi
      wget -qO "$tempDir/gh_api_res.json" "https://api.github.com/users/$USERNAME"
    else
      echo "Could not execute either 'curl' or 'wget' to fetch GitHub data. Please install one of the two."
      exit 1
    fi
  fi

  # Verify username matches github user data
  VERIFY_USERNAME=$(parseJsonStr login "$tempDir/gh_api_res.json")
  if [[ $DEBUG == 1 && "$USERNAME" == "" ]]; then
    echo "    [DEBUG] Setting \$USERNAME to cached value"
    USERNAME="$VERIFY_USERNAME"
  fi
  if [[ "$USERNAME" != "$VERIFY_USERNAME" ]]; then
    echo "Received mismatched username data. (Username requested: $USERNAME) (Username received: $VERIFY_USERNAME)"
    exit 1
  fi

  USER_ID=$(parseJsonNum id "$tempDir/gh_api_res.json")

  DO_GIT_LFS=1
  if yn_prompt "    Enable Git-LFS in \e[0;36m$HOME/.gitconfig\e[0m? (still need to install on your system)" 0; then
    if [[ $DEBUG == 1 ]]; then
      echo "    [DEBUG] Enabling Git-LFS"
    fi

    DO_GIT_LFS=0
  fi

  AUTO_CRLF=''
  case "$OSTYPE" in
    "linux-gnu") AUTO_CRLF='input';;
    "msys")      AUTO_CRLF='true';;
  esac
  echo -e "    Setting \e[0;36mcore.autocrlf\e[0m to \e[0;36m$AUTO_CRLF\e[0m since this is a \e[0;36m$OS_TYPE_DESCRIPTOR\e[0m system. "

  read -rp $'    Enter Git text editor executable (default: \e[0;36mvim\e[0m): ' GIT_EDITOR
  if [[ "$GIT_EDITOR" == "" ]]; then
    if [[ $DEBUG == 1 ]]; then
      echo "    [DEBUG] Setting \$GIT_EDITOR to default value"
    fi
    GIT_EDITOR="vim"
  fi

  # Generate .gitconfig in temp directory and parse in values
  echo -e "    Generating \e[0;36m$HOME/.gitconfig\e[0m based on \e[0;36m$projectDir/template.gitconfig\e[0m"
  cp "$projectDir/template.gitconfig" "$tempDir/.gitconfig"
  if [[ $DO_GIT_LFS == 0 ]]; then
    GIT_LFS_STR=$'[filter "lfs"]\n  smudge = git-lfs smudge -- %f\n  process = git-lfs filter-process\n  required = true\n  clean = git-lfs clean -- %f'
    echo "$GIT_LFS_STR" >> "$tempDir/.gitconfig"
  fi
  sed -i "s/##USERNAME##/$USERNAME/g" "$tempDir/.gitconfig"
  sed -i "s/##USER_ID##/$USER_ID/g" "$tempDir/.gitconfig"
  sed -i "s/##AUTO_CRLF##/$AUTO_CRLF/g" "$tempDir/.gitconfig"
  sed -i "s/##GIT_EDITOR##/$GIT_EDITOR/g" "$tempDir/.gitconfig"

  if [[ $DEBUG == 1 ]]; then
    echo -e "    [DEBUG] Skipping copy of \e[0;36m.gitconfig\e[0m to home directory"
  else
    cat "$tempDir/.gitconfig" > "$HOME/.gitconfig"
  fi
else
  echo -e "    Skipping \e[0;36m.gitconfig\e[0m"
fi


echo
if [[ $DEBUG == 1 ]]; then
  echo "[DEBUG] Skipping cleaning up temporary files"
else
  echo "Cleaning up temporary files"
  rm -r "$tempDir"
fi

echo "Install complete!"
