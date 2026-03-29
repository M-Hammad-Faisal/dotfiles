#!/bin/bash
set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG="$DOTFILES_DIR/config.json"

BLUE='\033[0;34m'
GREEN='\033[0;32m'
NC='\033[0m'

info()    { echo -e "${BLUE}[brew]${NC} $1"; }
success() { echo -e "${GREEN}[brew]${NC} $1"; }

# Source Homebrew
eval "$(/opt/homebrew/bin/brew shellenv)"

# ─── Install packages ──────────────────────────────────────────────────────────
info "Reading packages from config.json..."

PACKAGES=$(jq -r '.brew.packages.defaults[], .brew.packages.extras[]' "$CONFIG")
CASKS=$(jq -r '.brew.casks.defaults[], .brew.casks.extras[]' "$CONFIG")

info "Installing brew packages..."
while IFS= read -r pkg; do
  [ -z "$pkg" ] && continue
  if brew list --formula "$pkg" &>/dev/null; then
    info "  Already installed: $pkg"
  else
    info "  Installing: $pkg"
    brew install "$pkg"
    success "  Installed: $pkg"
  fi
done <<< "$PACKAGES"

info "Installing brew casks..."
while IFS= read -r cask; do
  [ -z "$cask" ] && continue
  if brew list --cask "$cask" &>/dev/null; then
    info "  Already installed (cask): $cask"
  else
    info "  Installing cask: $cask"
    brew install --cask "$cask"
    success "  Installed cask: $cask"
  fi
done <<< "$CASKS"

success "All brew packages and casks are up to date."
