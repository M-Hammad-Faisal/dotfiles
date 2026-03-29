#!/bin/bash
set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG="$DOTFILES_DIR/config.json"

# ─── Colors ────────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
error()   { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# ─── Parse --only=<module> flag ────────────────────────────────────────────────
ONLY_MODULE=""
for arg in "$@"; do
  case "$arg" in
    --only=*) ONLY_MODULE="${arg#--only=}" ;;
  esac
done

# ─── Step 0: Ensure Homebrew is present ────────────────────────────────────────
if ! command -v brew &>/dev/null; then
  info "Homebrew not found. Installing..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  success "Homebrew installed."
fi

# Source Homebrew into PATH (Apple Silicon)
eval "$(/opt/homebrew/bin/brew shellenv)"
success "Homebrew sourced into PATH."

# ─── Step 1: Ensure jq is available ───────────────────────────────────────────
if ! command -v jq &>/dev/null; then
  info "jq not found. Installing via brew..."
  brew install jq
  success "jq installed."
fi

# ─── Config validation ────────────────────────────────────────────────────────
EXAMPLE="$DOTFILES_DIR/config.example.json"

if [ ! -f "$CONFIG" ]; then
  echo ""
  warn "config.json not found."
  info "Copying from config.example.json..."
  cp "$EXAMPLE" "$CONFIG"
  echo ""
  echo -e "${YELLOW}👉  Open $CONFIG and fill in your details, then re-run bootstrap.sh${NC}"
  echo ""
  exit 1
fi

success "config.json found."

# ─── Step 2: Run install/generate modules ─────────────────────────────────────
run_module() {
  local name="$1"
  local script="$2"
  if [ -z "$ONLY_MODULE" ] || [ "$ONLY_MODULE" = "$name" ]; then
    info "Running: $name"
    bash "$script"
    success "Done: $name"
  fi
}

# Install modules
run_module "brew"    "$DOTFILES_DIR/install/brew.sh"
run_module "node"    "$DOTFILES_DIR/install/node.sh"
run_module "python"      "$DOTFILES_DIR/install/python.sh"
run_module "npm_globals" "$DOTFILES_DIR/install/npm_globals.sh"
run_module "pip_globals" "$DOTFILES_DIR/install/pip_globals.sh"
run_module "mas"         "$DOTFILES_DIR/install/mas.sh"
run_module "gcloud"      "$DOTFILES_DIR/install/gcloud.sh"
run_module "ssh"         "$DOTFILES_DIR/install/ssh.sh"

# Generate config files
if [ -z "$ONLY_MODULE" ]; then
  info "Generating config files..."
  bash "$DOTFILES_DIR/generate/zshrc.sh"
  bash "$DOTFILES_DIR/generate/gitconfig.sh"
  bash "$DOTFILES_DIR/generate/ssh_config.sh"
  success "Config files generated."

  info "Running symlink.sh..."
  bash "$DOTFILES_DIR/symlink.sh"
  success "Symlinks created."
fi

# ─── Step 3: Print manual steps checklist ─────────────────────────────────────
if [ -z "$ONLY_MODULE" ]; then
  echo ""
  echo -e "${YELLOW}════════════════════════════════════════════════════${NC}"
  echo -e "${YELLOW}  MANUAL STEPS REMAINING${NC}"
  echo -e "${YELLOW}════════════════════════════════════════════════════${NC}"

  # SSH keys per account
  jq -c '.git.accounts[]' "$CONFIG" | while read -r account; do
    ALIAS=$(echo "$account" | jq -r '.host_alias')
    echo "[ ] Add SSH public key to GitHub for: $ALIAS"
  done

  # gcloud
  GCLOUD=$(jq -r '.gcloud.enabled' "$CONFIG")
  [ "$GCLOUD" = "true" ] && echo "[ ] Run: gcloud auth login"

  # manual installs
  MANUAL_COUNT=$(jq '.manual_installs | length' "$CONFIG")
  if [ "$MANUAL_COUNT" -gt 0 ]; then
    echo ""
    echo "Manual installs:"
    jq -r '.manual_installs[] | "[ ] \(.name) — \(.note // .url // "see docs")"' "$CONFIG"
  fi

  echo -e "${YELLOW}════════════════════════════════════════════════════${NC}"
  echo ""
  success "Bootstrap complete. Restart your terminal or run: source ~/.zshrc"
fi
