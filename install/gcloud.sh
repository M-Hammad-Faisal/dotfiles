#!/bin/bash
set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG="$DOTFILES_DIR/config.json"

BLUE='\033[0;34m'
GREEN='\033[0;32m'
NC='\033[0m'

info()    { echo -e "${BLUE}[gcloud]${NC} $1"; }
success() { echo -e "${GREEN}[gcloud]${NC} $1"; }

ENABLED=$(jq -r '.gcloud.enabled' "$CONFIG")

if [ "$ENABLED" != "true" ]; then
  info "gcloud disabled in config.json. Skipping."
  exit 0
fi

# Source Homebrew
eval "$(/opt/homebrew/bin/brew shellenv)"

if command -v gcloud &>/dev/null; then
  success "gcloud already installed: $(gcloud --version | head -1)"
  exit 0
fi

info "Installing Google Cloud SDK (arm64)..."

INSTALLER_URL="https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-darwin-arm.tar.gz"
TMP_DIR=$(mktemp -d)

info "Downloading installer to $TMP_DIR..."
curl -fsSL "$INSTALLER_URL" -o "$TMP_DIR/google-cloud-sdk.tar.gz"

info "Extracting..."
tar -xzf "$TMP_DIR/google-cloud-sdk.tar.gz" -C "$TMP_DIR"

info "Running install script..."
"$TMP_DIR/google-cloud-sdk/install.sh" --quiet --path-update=true

# Clean up
rm -rf "$TMP_DIR"

success "Google Cloud SDK installed."
info "You may need to restart your terminal for PATH changes to take effect."
info "Run 'gcloud init' to configure your account."
