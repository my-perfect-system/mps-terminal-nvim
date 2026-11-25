#!/usr/bin/env bash
# Install mps-terminal-nvim system packages on Fedora (dnf). Idempotent.
# Toggle (default matches the odem.terminal.nvim role): MPS_NVIM_ENABLE_DEPS
set -euo pipefail

ENABLE_DEPS="${MPS_NVIM_ENABLE_DEPS:-1}"

SUDO=""
[[ ${EUID} -eq 0 ]] || SUDO="sudo"

if [[ "${ENABLE_DEPS}" = 1 ]]; then
    ${SUDO} dnf install -y \
        make gcc gcc-c++ gdb wget bzip2 curl lldb ncurses-devel ruby npm \
        fzf fd-find rr ripgrep shellcheck xclip xsel luarocks python3 \
        python3-pip black pylint pandoc python3-neovim
fi
echo "mps-terminal-nvim packages installed (fedora)."