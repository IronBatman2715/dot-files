#!/bin/bash

# when leaving the console, clear the screen to increase privacy
if [ "$SHLVL" = 1 ]; then
  if command -v clear_console &> /dev/null; then
    clear_console -q
  elif command -v clear &> /dev/null; then
    clear
  else
    # Worst case scenario fallback. Sends the escape sequence to clear the screen
    printf "\033c"
  fi
fi
