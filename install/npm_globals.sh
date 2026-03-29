#!/bin/bash
set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG="$DOTFILES_DIR/config.json"

ENABLED=$(jq -r '.npm_globals.enabled' "$CONFIG")
if [ "$ENABLED" != "true" ]; then
  echo "npm_globals disabled in config. Skipping."
  exit 0
fi

echo "Installing global npm packages..."

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

PACKAGES=$(jq -r '.npm_globals.packages[]' "$CONFIG" 2>/dev/null)

if [ -z "$PACKAGES" ]; then
  echo "No npm global packages defined in config."
  exit 0
fi

for pkg in $PACKAGES; do
  if npm list -g "$pkg" &>/dev/null; then
    echo "Already installed: $pkg"
  else
    echo "Installing $pkg..."
    npm install -g "$pkg"
  fi
done

echo "npm globals done."
