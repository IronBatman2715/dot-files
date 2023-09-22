#!/bin/bash

## HELPER FUNCTIONS ##

function create_file_symlink() {
  local src_path="$projectDir/$1"
  local dest_path="$HOME/$1"

  if [[ ! -f "$src_path" ]]; then
    echo -e "  Creating empty \e[0;36m$src_path\e[0m"
    touch $src_path
  fi

  if [[ -e "$dest_path" ]]; then
    read -p $'  Something already exists at \e[0;36m'"$dest_path"$'\e[0m. Overwrite? [Y/n]: ' INPUT

    if [[ $INPUT == "" || ${INPUT,,} == "y" ]]; then
      echo -e "    Overwriting \e[0;36m$dest_path\e[0m"
      rm -rf $dest_path

      echo -e "    Creating symlink at \e[0;36m$dest_path\e[0m pointing to \e[0;36m$src_path\e[0m"
      ln -s $src_path $dest_path
    elif [[ ${INPUT,,} == "n" ]]; then
      echo -e "    Skipped install of \e[0;36m$1\e[0m"
    else
      echo -e "    \e[0;31mInvalid entry\e[0m. Skipping install of \e[0;36m$1\e[0m"
    fi
  else
    echo -e "  Creating symlink at \e[0;36m$dest_path\e[0m pointing to \e[0;36m$src_path\e[0m"
    ln -s $src_path $dest_path
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
  # /dev/stdin = JSON as text

  local key="$1"
  local re="\"($key)\": \"([^\"]*)\""

  while read -r l; do
    if [[ $l =~ $re ]]; then
      local name="${BASH_REMATCH[1]}"
      local value="${BASH_REMATCH[2]}"
      echo "$value"
      return
    fi
  done

  echo "Could not parse string!"; exit 1
}

### MAIN ###

# Set DEBUG=1 to run in debug mode (i.e. "DEBUG=1 ./install.bash")

if [[ $DEBUG != 1 ]]; then
  DEBUG=0 # Normal operation
fi
if [[ $DEBUG == 1 ]]; then
  echo "[DEBUG] Debug mode active!"
fi

projectDir=$(cd $(dirname "${BASH_SOURCE[0]}") && pwd)
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
create_file_symlink .bash_aliases
create_file_symlink .bash_profile
create_file_symlink .bash_program_setups
create_file_symlink .bashrc
create_file_symlink .vimrc

echo "Generating other files"

echo -e "  Generating .gitconfig (this will overwrite \e[0;36m$HOME/.gitconfig\e[0m if present)"
read -p $'    Enter GitHub username [leave blank to skip \e[0;36m.gitconfig\e[0m]: ' USERNAME
if [[ "$USERNAME" != "" || $DEBUG == 1 ]]; then
  if [[ ! -e "$tempDir/gh_api_res.json" ]]; then
    if [[ $DEBUG == 1 && "$USERNAME" == "" ]]; then
      echo "[DEBUG] Must enter GitHub username at least one time to test further"; exit 1
    fi

    echo -e "    Sending request to \e[0;36mhttps://api.github.com/users/$USERNAME\e[0m"
    curl -so "$tempDir/gh_api_res.json" "https://api.github.com/users/$USERNAME"

    # Verify username matches expected value
    VERIFY_USERNAME=$(cat "$tempDir/gh_api_res.json" | parseJsonStr login)
    if [[ "$USERNAME" != "$VERIFY_USERNAME" ]]; then
      echo "Received mismatched username data. (Username requested: $USERNAME) (Username received: $VERIFY_USERNAME)"
      exit 1
    fi
  fi

  USER_ID=$(cat "$tempDir/gh_api_res.json" | parseJsonNum id)

  echo -e "    Generating \e[0;36m$HOME/.gitconfig\e[0m based on \e[0;36m$projectDir/template.gitconfig\e[0m"
  cp "$projectDir/template.gitconfig" "$tempDir/.gitconfig"
  sed -i "s/##USERNAME##/$USERNAME/g" "$tempDir/.gitconfig"
  sed -i "s/##USER_ID##/$USER_ID/g" "$tempDir/.gitconfig"

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
