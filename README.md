# mps-terminal-nvim

Neovim configuration of the [my-perfect-system](https://github.com/my-perfect-system) (mps) terminal stack — a lightweight, fast Neovim 0.12+ setup built on native APIs: [lazy.nvim](https://lazy.folke.io), native `vim.lsp` (no lspconfig), blink.cmp with LuaSnip. Authoring rules live in [AGENTS.md](AGENTS.md).

## Install

| Method | Description |
|---|---|
| Default | `bootstrap.sh` clones to the system-wide mps repo dir and runs `install.sh` |
| Ansible | can be used by installing via the `odem.terminal.nvim` role of [odem-terminal](https://github.com/my-perfect-system/odem-terminal) |
| Standalone | clone the repo, then run `./install.sh` inside it; no network needed |

### Install (Default)

```bash
curl -fsSL https://raw.githubusercontent.com/my-perfect-system/mps-terminal-nvim/main/bootstrap.sh | bash
```

All methods deploy `config/nvim/` to the current user's `~/.config/nvim`; one clone
per host (`${MPS_REPO_DIR:-/srv/repo/github/my-perfect-system}`), shared by all
users. Plugins install on first start (`nvim +Lazy! sync`).

## Usage

```bash
nvim file.py                    # open a file; plugins install on first start
nvim --headless -c "q"          # verify the config loads without errors
cfg-nvim                        # edit ~/.config/nvim/init.lua
                                # (alias from mps-terminal-bash-aliases)
```

## Creating new plugins

```bash
echo 'return { "folke/trouble.nvim" }' > config/nvim/lua/tools/trouble.lua
                                                # one spec file per plugin in the
                                                # right lua/<category>/ dir, plus a
                                                # require in the dir's init.lua
git add config/nvim && git commit -m "Add trouble plugin" && git push
curl -fsSL https://raw.githubusercontent.com/my-perfect-system/mps-terminal-nvim/main/bootstrap.sh | bash
                                                # redeploy: pulls the clone,
                                                # copies to ~/.config/nvim
```