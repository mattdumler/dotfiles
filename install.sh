#!/usr/bin/env bash
# Cross-platform package installer for dotfiles.
# Installs core packages via apt (Linux) or brew (macOS),
# sets zsh as default shell, and installs Node.js via nvm
# (used by Mason-managed Node-based LSP servers).
#
# TODO: add a companion update.sh to refresh tools across all install methods
# in use here (apt, brew, GitHub release tarball, nvm, Claude installer,
# Mason). A single entry point beats remembering which tool came from where.
set -eu

# Tarball-installed nvim and nvm-symlinked node both land in ~/.local/bin.
# A fresh shell won't have this on PATH yet, so the script's own version
# checks (e.g. require_nvim_010) wouldn't find them.
export PATH="$HOME/.local/bin:$PATH"

# Packages available by the same name on both apt and brew.
# clang-format: installed here (not via Mason) because Mason's pypi provider
# rejects the clang-format package — its PyPI metadata lacks requires_python.
packages=(stow fzf tmux ripgrep pre-commit clang-format)

# Neovim plugins (lazy.nvim, blink.cmp, native inlay hints) require 0.10+.
require_nvim_010() {
    if ! command -v nvim >/dev/null; then
        echo "Error: nvim not found on PATH." >&2
        exit 1
    fi
    local version
    version=$(nvim --version | head -1 | awk '{print $2}' | tr -d 'v')
    local major minor
    major=$(echo "$version" | cut -d. -f1)
    minor=$(echo "$version" | cut -d. -f2)
    if [ "$major" -eq 0 ] && [ "$minor" -lt 10 ]; then
        echo "Error: Neovim >= 0.10 required, found $version." >&2
        echo "On Linux: reinstall via install_nvim_linux (upstream tarball)." >&2
        exit 1
    fi
}

install_linux() {
    sudo apt update
    sudo apt install -y curl git zsh "${packages[@]}"

    # Packages with different names on apt vs brew.
    # unzip: Mason uses it to extract downloaded tool archives.
    # fd-find: Telescope uses fd for fast file listing; binary is `fdfind` on apt.
    sudo apt install -y build-essential cmake unzip fd-find

    install_nvim_linux

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

    brew install "${packages[@]}" neovim cmake fd
}

# Install latest stable Neovim from upstream tarball.
# Apt (Ubuntu 22.04) ships 0.7.2 and the neovim-ppa is unreliable on Jammy.
install_nvim_linux() {
    # Remove any apt-installed neovim so it can't shadow the tarball binary on PATH.
    if dpkg -s neovim >/dev/null 2>&1; then
        sudo apt remove -y neovim
    fi

    if [ -x "$HOME/.local/bin/nvim" ] \
        && dpkg --compare-versions "$("$HOME/.local/bin/nvim" --version | head -1 | awk '{print $2}' | tr -d 'v')" ge 0.10.0; then
        echo "Neovim $("$HOME/.local/bin/nvim" --version | head -1) already installed"
        return
    fi
    local tmp
    tmp=$(mktemp -d)
    curl -fsSL -o "$tmp/nvim.tar.gz" \
        https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
    mkdir -p "$HOME/.local"
    tar -C "$HOME/.local" -xzf "$tmp/nvim.tar.gz"
    mkdir -p "$HOME/.local/bin"
    ln -sf "$HOME/.local/nvim-linux-x86_64/bin/nvim" "$HOME/.local/bin/nvim"
    rm -rf "$tmp"
}

# Install Node.js via nvm (used by Mason-managed Node-based LSP servers).
install_node() {
    export NVM_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/nvm"

    if [ -s "$NVM_DIR/nvm.sh" ]; then
        echo "nvm already installed"
    else
        # nvm's installer refuses to create a non-default NVM_DIR, so pre-create it.
        mkdir -p "$NVM_DIR"
        # NVM install script honors $NVM_DIR; PROFILE=/dev/null skips shell profile edits.
        PROFILE=/dev/null curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh" | bash
    fi

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
        # Pipe to bash, not sh — on Debian/Ubuntu /bin/sh is dash and the
        # installer uses bash-only syntax.
        curl -fsSL https://claude.ai/install.sh | bash
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
