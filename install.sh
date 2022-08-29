#!/bin/bash

projectDir=$(cd $(dirname "${BASH_SOURCE[0]}") && pwd)

function create_symlink() {
  src_path="$projectDir/$1"
  dest_path="$HOME/$1"

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
  VALUE_PATTERN="[0-9]*"
  LINE_PATTERN="\"$1\":\s*${VALUE_PATTERN}\s*,?"
  
  case $# in
    1)
      cat /dev/stdin | grep -oE "$LINE_PATTERN" | grep -oE "$VALUE_PATTERN"
    ;;
    2)
      grep -oE "$LINE_PATTERN" "$2" | grep -oE "$VALUE_PATTERN"
    ;;
    *)
      echo "Must enter a key to parse and then either pipe in the JSON or enter the JSON file name!"
      exit 1
    ;;
  esac
}

tempDir="$projectDir/.temp"
if [[ -e "$tempDir" ]]; then
  echo "Delete or rename $tempDir. As this program needs to create a directory there."
  exit 1
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
  # eventually parse username from json...?
  USER_ID=$(cat "$tempDir/gh_api_res.json" | parseJsonNum id)

  echo -e "    Generating \e[0;36m$HOME/.gitconfig\e[0m based on \e[0;36m$projectDir/.gitconfig\e[0m"
  cp "$projectDir/.gitconfig" "$tempDir/.gitconfig"
  sed -i "s/##USERNAME##/$USERNAME/g" "$tempDir/.gitconfig"
  sed -i "s/##USER_ID##/$USER_ID/g" "$tempDir/.gitconfig"

  cat "$tempDir/.gitconfig" > "$HOME/.gitconfig"
else
  echo -e "    Skipping \e[0;36m.gitconfig\e[0m"
fi

echo
echo "Cleaning up temporary files"
# Comment this out during testing to prevent unecessary API calls
rm -r "$tempDir"

echo "Install complete!"
