#!/usr/bin/env bash
# Cross-platform package installer for dotfiles.
# Installs core packages via apt (Linux) or brew (macOS),
# sets zsh as default shell, and installs Node.js via nvm.
set -eu

# Packages available by the same name on both apt and brew.
packages=(stow neovim fzf tmux ripgrep pre-commit)

install_linux() {
    if grep -q "Ubuntu" /etc/os-release; then
        sudo add-apt-repository -y ppa:neovim-ppa/stable
    fi

    sudo apt update
    sudo apt install -y curl git zsh "${packages[@]}"

    # Packages with different names on apt vs brew.
    sudo apt install -y build-essential cmake

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

    brew install "${packages[@]}" cmake
}

# Install Node.js via nvm (for coc.nvim).
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

    # Expose node on PATH without sourcing nvm in every shell (needed by nvim/coc).
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

install_node
install_claude_code

echo "Package installation complete."
