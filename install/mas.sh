#!/bin/bash
set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG="$DOTFILES_DIR/config.json"

ENABLED=$(jq -r '.mas.enabled' "$CONFIG")
if [ "$ENABLED" != "true" ]; then
  echo "Mac App Store installs disabled in config. Skipping."
  exit 0
fi

echo "Installing Mac App Store apps..."

# Source Homebrew (needed for mas install check)
eval "$(/opt/homebrew/bin/brew shellenv)"

brew list mas &>/dev/null || brew install mas

APP_COUNT=$(jq '.mas.apps | length' "$CONFIG")
if [ "$APP_COUNT" -eq 0 ]; then
  echo "No MAS apps defined in config."
  exit 0
fi

jq -c '.mas.apps[]' "$CONFIG" | while read -r app; do
  ID=$(echo "$app"   | jq -r '.id')
  NAME=$(echo "$app" | jq -r '.name')

  if mas list | grep -q "$ID"; then
    echo "Already installed: $NAME"
  else
    echo "Installing $NAME ($ID)..."
    mas install "$ID"
  fi
done

echo "MAS installs done."
