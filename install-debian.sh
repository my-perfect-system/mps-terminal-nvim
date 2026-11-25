#!/usr/bin/env bash
# Install mps-terminal-nvim system packages on Debian (apt). Idempotent.
# Toggle (default matches the odem.terminal.nvim role): MPS_NVIM_ENABLE_DEPS
set -euo pipefail

ENABLE_DEPS="${MPS_NVIM_ENABLE_DEPS:-1}"

SUDO=""
[[ ${EUID} -eq 0 ]] || SUDO="sudo"

if [[ "${ENABLE_DEPS}" = 1 ]]; then
    ${SUDO} apt-get install -y \
        lazygit make gcc gdb wget bzip2 curl build-essential lldb \
        libncurses-dev ruby npm fzf fd-find rr ripgrep shellcheck xclip xsel \
        luarocks chktex ansible-lint python3 python3-venv python3-pip \
        black flake8 pylint mypy pandoc python3-neovim python3-pynvim
fi
echo "mps-terminal-nvim packages installed (debian)."