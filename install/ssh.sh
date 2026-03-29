#!/bin/bash
set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG="$DOTFILES_DIR/config.json"

BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()    { echo -e "${BLUE}[ssh]${NC} $1"; }
success() { echo -e "${GREEN}[ssh]${NC} $1"; }
warn()    { echo -e "${YELLOW}[ssh]${NC} $1"; }

SSH_DIR="$HOME/.ssh"
mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"

# Start ssh-agent if not running
if [ -z "$SSH_AUTH_SOCK" ]; then
  eval "$(ssh-agent -s)" > /dev/null
fi

# ─── Loop through accounts ────────────────────────────────────────────────────
ACCOUNTS=$(jq -c '.git.accounts[]' "$CONFIG")

while IFS= read -r account; do
  NAME=$(echo "$account"      | jq -r '.name')
  EMAIL=$(echo "$account"     | jq -r '.email')
  HOST_ALIAS=$(echo "$account"| jq -r '.host_alias')
  KEY_NAME=$(echo "$account"  | jq -r '.key_name')

  KEY_PATH="$SSH_DIR/$KEY_NAME"

  echo ""
  info "Account: $NAME ($EMAIL)"
  info "Host alias: $HOST_ALIAS"

  if [ -f "$KEY_PATH" ]; then
    warn "Key already exists: $KEY_PATH — skipping generation."
  else
    info "Generating SSH key: $KEY_PATH"
    ssh-keygen -t ed25519 -C "$EMAIL" -f "$KEY_PATH"
    success "Key generated: $KEY_PATH"
  fi

  # Set key file permissions
  chmod 600 "$KEY_PATH"
  chmod 644 "${KEY_PATH}.pub"

  # Add to ssh-agent with Apple Keychain
  info "Adding $KEY_NAME to ssh-agent (Apple Keychain)..."
  ssh-add --apple-use-keychain "$KEY_PATH" 2>/dev/null || \
    ssh-add "$KEY_PATH" 2>/dev/null || \
    warn "Could not add key to agent — you may need to add it manually."

  # Print public key for GitHub
  echo ""
  echo -e "${GREEN}═══ Public key for: $NAME ($HOST_ALIAS) ═══${NC}"
  cat "${KEY_PATH}.pub"
  echo ""

done <<< "$ACCOUNTS"

success "SSH setup complete. Add each public key above to its corresponding GitHub account."
