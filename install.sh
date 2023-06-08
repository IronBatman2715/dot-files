#!/bin/bash

## HELPER FUNCTIONS ##

function create_symlink() {
  local src_path="$projectDir/$1"
  local dest_path="$HOME/$1"

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

projectDir=$(cd $(dirname "${BASH_SOURCE[0]}") && pwd)
tempDir="$projectDir/.temp"
if [[ -e "$tempDir" ]]; then
  echo "Delete or rename $tempDir. As this program needs to create a directory there."; exit 1
fi
mkdir "$tempDir"

echo "Creating symlinks"
create_symlink .bash_aliases
create_symlink .bash_profile
create_symlink .bashrc
create_symlink .vimrc

echo "Generating other files"

echo "  Generating .gitconfig"
read -p $'    Enter GitHub username [leave blank to skip \e[0;36m.gitconfig\e[0m]: ' USERNAME
if [[ "$USERNAME" != "" ]]; then
  if [[ ! -e "$tempDir/gh_api_res.json" ]]; then
    echo -e "    Sending request to \e[0;36mhttps://api.github.com/users/$USERNAME\e[0m"
    curl -so "$tempDir/gh_api_res.json" "https://api.github.com/users/$USERNAME"
  fi

  # Verify username matches expected value
  VERIFY_USERNAME=$(cat "$tempDir/gh_api_res.json" | parseJsonStr login)
  if [[ "$USERNAME" != "$VERIFY_USERNAME" ]]; then
    echo "Received mismatched username data. (Username requested: $USERNAME) (Username received: $VERIFY_USERNAME)"; exit 1
  fi

  USER_ID=$(cat "$tempDir/gh_api_res.json" | parseJsonNum id)

  echo -e "    Generating \e[0;36m$HOME/.gitconfig\e[0m based on \e[0;36m$projectDir/.gitconfig\e[0m"
  cp "$projectDir/template.gitconfig" "$tempDir/.gitconfig"
  sed -i "s/##USERNAME##/$USERNAME/g" "$tempDir/.gitconfig"
  sed -i "s/##USER_ID##/$USER_ID/g" "$tempDir/.gitconfig"

  cat "$tempDir/.gitconfig" > "$HOME/.gitconfig"
else
  echo -e "    Skipping \e[0;36m.gitconfig\e[0m"
fi

echo
echo "Cleaning up temporary files"
rm -r "$tempDir" # Comment this out during testing to prevent unecessary API calls

echo "Install complete!"
