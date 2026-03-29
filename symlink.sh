#!/bin/bash
set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$DOTFILES_DIR/config"

BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()    { echo -e "${BLUE}[symlink]${NC} $1"; }
success() { echo -e "${GREEN}[symlink]${NC} $1"; }
warn()    { echo -e "${YELLOW}[symlink]${NC} $1"; }

TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# ─── Helper: backup and symlink ───────────────────────────────────────────────
link_file() {
  local src="$1"   # file in config/
  local dest="$2"  # target location (e.g. ~/.zshrc)

  if [ ! -f "$src" ]; then
    warn "Source not found, skipping: $src"
    return
  fi

  # Backup existing real file (not a symlink)
  if [ -f "$dest" ] && [ ! -L "$dest" ]; then
    local backup="${dest}.backup.${TIMESTAMP}"
    warn "Backing up existing $dest → $backup"
    mv "$dest" "$backup"
  fi

  # Remove stale symlink
  if [ -L "$dest" ]; then
    info "Removing existing symlink: $dest"
    rm "$dest"
  fi

  # Ensure parent directory exists
  mkdir -p "$(dirname "$dest")"

  ln -s "$src" "$dest"
  success "Linked: $dest → $src"
}

# ─── Symlink map ──────────────────────────────────────────────────────────────
link_file "$CONFIG_DIR/.zshrc"             "$HOME/.zshrc"
link_file "$CONFIG_DIR/.gitconfig"         "$HOME/.gitconfig"
link_file "$CONFIG_DIR/.gitignore_global"  "$HOME/.gitignore_global"
link_file "$CONFIG_DIR/.ssh/config"        "$HOME/.ssh/config"

success "All symlinks created."
