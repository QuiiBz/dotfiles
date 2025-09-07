#!/usr/bin/env bash

run() {
  echo " "
  echo -e "\033[1m$1...\033[0m"

  # Remove the first argument and execute all the other arguments as a command
  shift
  "$@"
}

force=false
for arg in "$@"; do
  if [[ "$arg" == "--force" ]]; then
    force=true
    break
  fi
done

# Exit immediately if a command exits with a non-zero status
set -e

# Dotfiles
run "Updating dotfiles" cd ~/.home && git pull && ./update.sh <<< y && cd -

# Homebrew
run "Updating homebrew" brew update
run "Upgrading homebrew packages" brew upgrade
run "Cleaning up homebrew" brew cleanup

# Third-party package managers
run "Updating proto" proto upgrade
run "Updating global pnpm packages" pnpm update -g

# Tools
run "Updating tldr pages" tldr --update
run "Building bat cache" bat cache --build

# Neovim
# run "Updating Neovim" bob install stable
if [[ "$force" == true ]]; then
  run "Updating Neovim plugins" nvim --headless +Lazy! sync +qa
else
  run "Syncing Neovim plugins" nvim --headless +Lazy! restore +qa
fi
run "Updating Mason packages" nvim --headless +MasonUpdate +qa
