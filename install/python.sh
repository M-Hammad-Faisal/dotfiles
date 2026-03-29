#!/bin/bash
set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG="$DOTFILES_DIR/config.json"

BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()    { echo -e "${BLUE}[python]${NC} $1"; }
success() { echo -e "${GREEN}[python]${NC} $1"; }
warn()    { echo -e "${YELLOW}[python]${NC} $1"; }

VERSION=$(jq -r '.python.version' "$CONFIG")
FALLBACK=$(jq -r '.python.fallback' "$CONFIG")

# Source Homebrew
eval "$(/opt/homebrew/bin/brew shellenv)"

# ─── Install pyenv ────────────────────────────────────────────────────────────
if ! command -v pyenv &>/dev/null; then
  info "pyenv not found. Installing via brew..."
  brew install pyenv
  success "pyenv installed."
fi

export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

# ─── Resolve version ──────────────────────────────────────────────────────────
resolve_version() {
  local v="$1"
  if [ "$v" = "latest" ]; then
    pyenv install --list | grep -E '^\s+3\.[0-9]+\.[0-9]+$' | tail -1 | tr -d ' '
  else
    echo "$v"
  fi
}

RESOLVED=$(resolve_version "$VERSION")
info "Installing Python version: $RESOLVED (from config: $VERSION)"

# ─── Install with fallback ────────────────────────────────────────────────────
if pyenv install -s "$RESOLVED"; then
  pyenv global "$RESOLVED"
  success "Python $RESOLVED installed and set as global."
else
  warn "Failed to install Python $RESOLVED. Trying fallback: $FALLBACK"
  RESOLVED_FALLBACK=$(resolve_version "$FALLBACK")
  pyenv install -s "$RESOLVED_FALLBACK"
  pyenv global "$RESOLVED_FALLBACK"
  warn "Using fallback Python: $RESOLVED_FALLBACK"
fi

# ─── Print version ────────────────────────────────────────────────────────────
success "Python version: $(python --version)"
