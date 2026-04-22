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

# Install vim-plug if not present.
PLUG_VIM="$XDG_DATA_HOME/nvim/site/autoload/plug.vim"
if [ ! -f "$PLUG_VIM" ]; then
    echo "Installing vim-plug..."
    curl -fLo "$PLUG_VIM" --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
else
    echo "vim-plug already installed"
fi

# Install tpm if not present.
TPM_DIR="$XDG_DATA_HOME/tmux/plugins/tpm"
if [ ! -d "$TPM_DIR" ]; then
    echo "Installing tpm..."
    git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
else
    echo "tpm already installed"
fi

# Install vim plugins headlessly.
echo "Installing vim plugins..."
nvim --headless +PlugInstall +qall 2>/dev/null || true

# Install tmux plugins headlessly.
if [ -x "$TPM_DIR/bin/install_plugins" ]; then
    echo "Installing tmux plugins..."
    "$TPM_DIR/bin/install_plugins"
fi

echo "Setup complete."
