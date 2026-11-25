#!/usr/bin/env bash
# Deploy mps-terminal-nvim to the current user's ~/.config/nvim. Idempotent.
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONF_SRC="${SRC}/config/nvim"
DEST="${HOME}/.config/nvim"

install -d -m 0755 "${DEST}"
cp -a "${CONF_SRC}/." "${DEST}/"

echo "mps-terminal-nvim deployed to ${DEST}. Run: nvim"