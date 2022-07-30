#!/bin/bash

projectDir=$(cd $(dirname "${BASH_SOURCE[0]}") && pwd)

function create_symlink() {
  src_path="$projectDir/$1"
  dest_path="$HOME/$1"

  if [[ -e "$dest_path" ]]; then
    read -p $'Something already exists at \e[0;36m'"$dest_path"$'\e[0m. Overwrite? [Y/n]: ' INPUT

    if [[ $INPUT == "" || ${INPUT,,} == "y" ]]; then
      echo -e "Overwriting \e[0;36m$dest_path\e[0m"
      rm -rf $dest_path

      echo -e "Creating symlink at \e[0;36m$dest_path\e[0m pointing to \e[0;36m$src_path\e[0m"
      ln -s $src_path $dest_path
    elif [[ ${INPUT,,} == "n" ]]; then
      echo -e "Skipped install of \e[0;36m$1\e[0m"
    else
      echo -e "\e[0;31mInvalid entry\e[0m. Skipping install of \e[0;36m$1\e[0m"
    fi
  else
    echo -e "Creating symlink at \e[0;36m$dest_path\e[0m pointing to \e[0;36m$src_path\e[0m"
    ln -s $src_path $dest_path
  fi
  echo
}

create_symlink .bash_aliases
create_symlink .bash_profile
create_symlink .bashrc
create_symlink .vimrc

echo "Install complete!"