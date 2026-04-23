#!/usr/bin/env bash
# Cross-platform package installer for dotfiles.
# Installs core packages via apt (Linux) or brew (macOS),
# sets zsh as default shell, and installs Node.js via nvm
# (used by Mason-managed Node-based LSP servers).
set -eu

# Packages available by the same name on both apt and brew.
packages=(stow neovim fzf tmux ripgrep pre-commit)

# Neovim plugins (lazy.nvim, blink.cmp, native inlay hints) require 0.10+.
require_nvim_010() {
    local version
    version=$(nvim --version | head -1 | awk '{print $2}' | tr -d 'v')
    local major minor
    major=$(echo "$version" | cut -d. -f1)
    minor=$(echo "$version" | cut -d. -f2)
    if [ "$major" -eq 0 ] && [ "$minor" -lt 10 ]; then
        echo "Error: Neovim >= 0.10 required, found $version." >&2
        echo "On apt: ensure ppa:neovim-ppa/stable or use the AppImage." >&2
        exit 1
    fi
}

install_linux() {
    if grep -q "Ubuntu" /etc/os-release; then
        sudo add-apt-repository -y ppa:neovim-ppa/stable
    fi

    sudo apt update
    sudo apt install -y curl git zsh "${packages[@]}"

    # Packages with different names on apt vs brew.
    # unzip: Mason uses it to extract downloaded tool archives.
    # fd-find: Telescope uses fd for fast file listing; binary is `fdfind` on apt.
    sudo apt install -y build-essential cmake unzip fd-find

    # Symlink fdfind -> fd on PATH so Telescope picks it up.
    mkdir -p "$HOME/.local/bin"
    if command -v fdfind &>/dev/null && ! command -v fd &>/dev/null; then
        ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
    fi

    # Set zsh as default shell if not already.
    user_shell=$(getent passwd "$USER" | cut -d: -f7)
    case "$user_shell" in
        */zsh) echo "Default shell is already zsh" ;;
        *)
            echo "Setting default shell to zsh"
            chsh -s "$(command -v zsh)"
            ;;
    esac
}

install_macos() {
    # Ensure Homebrew is on PATH (not yet in PATH on a fresh machine).
    if ! command -v brew &>/dev/null; then
        if [ -x /opt/homebrew/bin/brew ]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        elif [ -x /usr/local/bin/brew ]; then
            eval "$(/usr/local/bin/brew shellenv)"
        else
            echo "Error: Homebrew is required. Install from https://brew.sh" >&2
            exit 1
        fi
    fi

    brew install "${packages[@]}" cmake fd
}

# Install Node.js via nvm (used by Mason-managed Node-based LSP servers).
install_node() {
    if [ -d "$HOME/.nvm" ]; then
        echo "nvm already installed"
    else
        curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh" | bash
    fi

    export NVM_DIR="$HOME/.nvm"
    # shellcheck source=/dev/null
    [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
    nvm install --lts

    # Expose node on PATH without sourcing nvm in every shell.
    mkdir -p "$HOME/.local/bin"
    ln -sf "$(nvm which current)" "$HOME/.local/bin/node"
}

# Install Claude Code via native installer.
install_claude_code() {
    if command -v claude &>/dev/null; then
        echo "Claude Code already installed"
    else
        echo "Installing Claude Code..."
        curl -fsSL https://claude.ai/install.sh | sh
    fi
}

case "$(uname -s)" in
    Linux)  install_linux ;;
    Darwin) install_macos ;;
    *)      echo "Unsupported OS: $(uname -s)" >&2; exit 1 ;;
esac

require_nvim_010
install_node
install_claude_code

echo "Package installation complete."
