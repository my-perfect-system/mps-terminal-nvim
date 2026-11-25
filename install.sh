#!/usr/bin/env bash
# Deploy mps-terminal-nvim to the current user's ~/.config/nvim plus system
# and per-user tools. Idempotent.
# OS-specific packages live in install-debian.sh / install-fedora.sh and are
# installed best-effort before the config deploy.
# Toggles (defaults match the odem.terminal.nvim role):
#   MPS_NVIM_ENABLE_DEPS / MPS_NVIM_ENABLE_NPM_TOOLS / MPS_NVIM_ENABLE_TARBALL
#   MPS_NVIM_ENABLE_VENV / MPS_NVIM_ENABLE_YAZI / MPS_NVIM_ENABLE_FD /
#   MPS_NVIM_ENABLE_TREE_SITTER
#   MPS_NVIM_TARBALL_VERSION (default v0.12.1) / MPS_NVIM_YAZI_VERSION (v26.5.6)
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONF_SRC="${SRC}/config/nvim"
DEST="${HOME}/.config/nvim"

ENABLE_NPM_TOOLS="${MPS_NVIM_ENABLE_NPM_TOOLS:-1}"
ENABLE_TARBALL="${MPS_NVIM_ENABLE_TARBALL:-1}"
ENABLE_VENV="${MPS_NVIM_ENABLE_VENV:-1}"
ENABLE_YAZI="${MPS_NVIM_ENABLE_YAZI:-1}"
ENABLE_FD="${MPS_NVIM_ENABLE_FD:-1}"
ENABLE_TREE_SITTER="${MPS_NVIM_ENABLE_TREE_SITTER:-1}"
TARBALL_VERSION="${MPS_NVIM_TARBALL_VERSION:-v0.12.1}"
YAZI_VERSION="${MPS_NVIM_YAZI_VERSION:-v26.5.6}"

SUDO=""
[[ ${EUID} -eq 0 ]] || SUDO="sudo"

#--- Distro detection -----------------------------------------------------------
detect_distro() {
    local id
    id="$(grep -sE '^ID=' /etc/os-release | head -1 | cut -d= -f2 | tr -d '\"')"
    case "${id}" in
        debian|ubuntu) echo "debian" ;;
        fedora|rhel)   echo "fedora" ;;
        *)
            if command -v apt-get >/dev/null 2>&1; then echo "debian"
            elif command -v dnf >/dev/null 2>&1; then echo "fedora"
            else echo "none"; fi ;;
    esac
}

#--- System: distro packages (best-effort; DEPS toggle read by the OS script) ---
case "$(detect_distro)" in
    debian) "${SRC}/install-debian.sh" || echo "==> WARN: install-debian.sh failed; continuing" ;;
    fedora)  "${SRC}/install-fedora.sh" || echo "==> WARN: install-fedora.sh failed; continuing" ;;
    *)       echo "==> Unsupported distro — skipping system packages" ;;
esac

#--- System: npm tools (global) ---------------------------------------------------
# npm's global root differs per family (RedHat /usr/local/lib/node_modules).
if [[ "${ENABLE_NPM_TOOLS}" = 1 ]] && command -v npm >/dev/null 2>&1; then
    NPM_ROOT="$(npm root -g 2>/dev/null || echo /usr/lib/node_modules)"
    if [[ ! -e "${NPM_ROOT}/neovim" ]]; then
        ${SUDO} npm install -g neovim vint luacheck
    fi
fi

#--- System: nvim itself as upstream tarball -------------------------------------
# Same layout as the odem role: extract to /usr/share/mps/tools/nvim, symlink
# into /usr/local/bin (shadowing any distro nvim in /usr/bin).
TOOLS_DIR="/usr/share/mps/tools/nvim"
if [[ "${ENABLE_TARBALL}" = 1 && ! -x /usr/local/bin/nvim ]]; then
    ${SUDO} install -d -m 0755 "${TOOLS_DIR}"
    ${SUDO} curl -fsSL \
        "https://github.com/neovim/neovim/releases/download/${TARBALL_VERSION}/nvim-linux-x86_64.tar.gz" \
        -o "${TOOLS_DIR}/nvim-linux-x86_64.tar.gz"
    ${SUDO} tar -xzf "${TOOLS_DIR}/nvim-linux-x86_64.tar.gz" -C "${TOOLS_DIR}"
    ${SUDO} rm -f /usr/bin/nvim
    ${SUDO} ln -sf "${TOOLS_DIR}/nvim-linux-x86_64/bin/nvim" /usr/local/bin/nvim
fi

#--- Per-user: python venv for the remote plugin host ----------------------------
if [[ "${ENABLE_VENV}" = 1 ]] && command -v python3 >/dev/null 2>&1; then
    install -d -m 0700 "${HOME}/.venvs"
    if [[ ! -x "${HOME}/.venvs/nvim/bin/ruff-lsp" ]]; then
        python3 -m venv "${HOME}/.venvs/nvim"
        "${HOME}/.venvs/nvim/bin/pip" install --quiet ruff-lsp debugpy pynvim
    fi
fi

#--- Per-user: yazi file manager binaries (~/.cargo/bin like the odem role) ------
if [[ "${ENABLE_YAZI}" = 1 && ! -x "${HOME}/.cargo/bin/yazi" ]]; then
    tmp="$(mktemp -d)"
    curl -fsSL \
        "https://github.com/sxyazi/yazi/releases/download/${YAZI_VERSION}/yazi-x86_64-unknown-linux-gnu.zip" \
        -o "${tmp}/yazi.zip"
    unzip -q "${tmp}/yazi.zip" -d "${tmp}"
    install -d -m 0700 "${HOME}/.cargo/bin"
    install -m 0700 "${tmp}/yazi-x86_64-unknown-linux-gnu/yazi" "${HOME}/.cargo/bin/yazi"
    install -m 0700 "${tmp}/yazi-x86_64-unknown-linux-gnu/ya"   "${HOME}/.cargo/bin/ya"
    rm -rf "${tmp}"
fi

#--- Per-user: fd-find and tree-sitter-cli via cargo (best-effort) ---------------
if [[ "${ENABLE_FD}" = 1 ]] && command -v cargo >/dev/null 2>&1 \
   && [[ ! -x "${HOME}/.cargo/bin/fd" ]]; then
    cargo install --locked fd-find || echo "==> WARN: cargo fd-find failed"
fi
if [[ "${ENABLE_TREE_SITTER}" = 1 ]] && command -v cargo >/dev/null 2>&1 \
   && [[ ! -x "${HOME}/.cargo/bin/tree-sitter" ]]; then
    cargo install --locked tree-sitter-cli || echo "==> WARN: cargo tree-sitter-cli failed"
fi

#--- Config deploy ---------------------------------------------------------------
install -d -m 0755 "${DEST}"
cp -a "${CONF_SRC}/." "${DEST}/"
# Session state dir expected by the session plugin
install -d -m 0700 "${HOME}/.config/nvim-session"

echo "mps-terminal-nvim deployed to ${DEST}. Run: nvim"