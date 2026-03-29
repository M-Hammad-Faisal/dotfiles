#!/bin/bash
set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG="$DOTFILES_DIR/config.json"

BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()    { echo -e "${BLUE}[node]${NC} $1"; }
success() { echo -e "${GREEN}[node]${NC} $1"; }
warn()    { echo -e "${YELLOW}[node]${NC} $1"; }

VERSION=$(jq -r '.node.version' "$CONFIG")
FALLBACK=$(jq -r '.node.fallback' "$CONFIG")

# ─── Install nvm ───────────────────────────────────────────────────────────────
export NVM_DIR="$HOME/.nvm"

if [ ! -d "$NVM_DIR" ]; then
  info "nvm not found. Installing via curl..."
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
  success "nvm installed."
fi

# Load nvm
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

if ! command -v nvm &>/dev/null; then
  info "Sourcing nvm..."
  export NVM_DIR="$HOME/.nvm"
  \. "$NVM_DIR/nvm.sh"
fi

# ─── Resolve version alias ────────────────────────────────────────────────────
resolve_version() {
  local v="$1"
  if [ "$v" = "lts" ]; then
    echo "lts/*"
  elif [ "$v" = "latest" ]; then
    echo "node"
  else
    echo "$v"
  fi
}

RESOLVED=$(resolve_version "$VERSION")
info "Installing Node.js version: $RESOLVED (from config: $VERSION)"

# ─── Install with fallback ────────────────────────────────────────────────────
if nvm install "$RESOLVED"; then
  nvm alias default "$RESOLVED"
  success "Node.js $RESOLVED installed and set as default."
else
  warn "Failed to install Node.js $RESOLVED. Trying fallback: $FALLBACK"
  RESOLVED_FALLBACK=$(resolve_version "$FALLBACK")
  nvm install "$RESOLVED_FALLBACK"
  nvm alias default "$RESOLVED_FALLBACK"
  warn "Using fallback Node.js: $RESOLVED_FALLBACK"
fi

# ─── Print versions ───────────────────────────────────────────────────────────
success "Node version: $(node --version)"
success "npm  version: $(npm --version)"
