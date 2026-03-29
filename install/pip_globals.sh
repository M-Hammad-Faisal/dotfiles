#!/bin/bash
set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG="$DOTFILES_DIR/config.json"

ENABLED=$(jq -r '.pip_globals.enabled' "$CONFIG")
if [ "$ENABLED" != "true" ]; then
  echo "pip_globals disabled in config. Skipping."
  exit 0
fi

echo "Installing global pip packages..."

export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

PACKAGES=$(jq -r '.pip_globals.packages[]' "$CONFIG" 2>/dev/null)

if [ -z "$PACKAGES" ]; then
  echo "No pip global packages defined in config."
  exit 0
fi

for pkg in $PACKAGES; do
  if pip show "$pkg" &>/dev/null; then
    echo "Already installed: $pkg"
  else
    echo "Installing $pkg..."
    pip install "$pkg"
  fi
done

echo "pip globals done."
