#!/usr/bin/env bash
# Stow linker + plugin installer. Idempotent, runs as current user (no sudo).
set -eu

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$DOTFILES_DIR"

# Ensure Homebrew is on PATH (not yet in PATH on a fresh machine).
if [ "$(uname -s)" = "Darwin" ] && ! command -v brew &>/dev/null; then
    if [ -x /opt/homebrew/bin/brew ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [ -x /usr/local/bin/brew ]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi
fi

XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"

# Create XDG directories used by configs.
mkdir -p "$XDG_STATE_HOME/zsh"
mkdir -p "$XDG_CACHE_HOME/zsh"

# Stow all packages.
stow_packages=(zsh nvim git tmux)

echo "Stowing packages: ${stow_packages[*]}"
stow --restow --no-folding --target="$HOME" "${stow_packages[@]}"

# Clone zsh-syntax-highlighting plugin.
ZSH_PLUGIN_DIR="$XDG_DATA_HOME/zsh/plugins"
mkdir -p "$ZSH_PLUGIN_DIR"

if [ ! -d "$ZSH_PLUGIN_DIR/zsh-syntax-highlighting" ]; then
    echo "Installing zsh-syntax-highlighting..."
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git \
        "$ZSH_PLUGIN_DIR/zsh-syntax-highlighting"
else
    echo "zsh-syntax-highlighting already installed"
fi

# Clone catppuccin zsh-syntax-highlighting theme.
if [ ! -d "$ZSH_PLUGIN_DIR/catppuccin-zsh" ]; then
    echo "Installing catppuccin zsh theme..."
    git clone https://github.com/catppuccin/zsh-syntax-highlighting.git \
        "$ZSH_PLUGIN_DIR/catppuccin-zsh"
else
    echo "catppuccin-zsh already installed"
fi

# Install tpm if not present.
TPM_DIR="$XDG_DATA_HOME/tmux/plugins/tpm"
if [ ! -d "$TPM_DIR" ]; then
    echo "Installing tpm..."
    git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
else
    echo "tpm already installed"
fi

# Sync Neovim plugins. lazy.nvim self-bootstraps from init.lua.
echo "Syncing Neovim plugins..."
nvim --headless "+Lazy! sync" +qa

# Install Mason-managed tools (clangd, codelldb). Blocks until done.
# mason-tool-installer is lazy-loaded by nvim-lspconfig's BufReadPre trigger,
# which never fires in headless mode with no buffer — so force-load it first.
# MasonToolsInstallSync installs missing tools; MasonToolsUpdateSync only updates
# already-installed ones, so it silently no-ops on a fresh machine.
echo "Installing Mason tools..."
nvim --headless \
    "+lua require('lazy').load({ plugins = { 'mason.nvim', 'mason-tool-installer.nvim' } })" \
    "+MasonToolsInstallSync" \
    +qa

# Compile custom spellfile so :set spell picks it up.
SPELLFILE="$HOME/.config/nvim/spell/en.utf-8.add"
if [ -f "$SPELLFILE" ]; then
    echo "Compiling spellfile..."
    nvim --headless "+silent! mkspell! $SPELLFILE" +qa
fi

# Install tmux plugins headlessly.
if [ -x "$TPM_DIR/bin/install_plugins" ]; then
    echo "Installing tmux plugins..."
    "$TPM_DIR/bin/install_plugins"
fi

echo "Setup complete."
