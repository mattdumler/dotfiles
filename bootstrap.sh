#!/usr/bin/env bash
# Component-selectable installer + setup for dotfiles.
#
# Usage:
#   ./bootstrap.sh                  # install + configure all components
#   ./bootstrap.sh zsh              # only zsh (e.g. on a dev container)
#   ./bootstrap.sh zsh tmux git     # subset
#
# Components: zsh, nvim, tmux, git, claude, node
# Dependencies: nvim pulls in node (Mason LSPs need it).
set -eu

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$DOTFILES_DIR"

# Tarball-installed nvim and nvm-symlinked node both land in ~/.local/bin.
# A fresh shell won't have this on PATH yet.
export PATH="$HOME/.local/bin:$PATH"

OS="$(uname -s)"
ALL_COMPONENTS=(zsh nvim tmux git claude node)

XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"

# --- Selection helpers -------------------------------------------------

# Space-padded list, so " $name " membership tests work cleanly.
SELECTED=" "

select_component() {
    case "$SELECTED" in
        *" $1 "*) return ;;
    esac
    SELECTED="$SELECTED$1 "
}

is_selected() {
    case "$SELECTED" in
        *" $1 "*) return 0 ;;
    esac
    return 1
}

# --- Stow helper -------------------------------------------------------

# Move any pre-existing non-symlink target out of the way before stowing.
# Conflicts can arise from interrupted prior runs or hand-copied files;
# --restow refuses to replace regular files even if their content matches.
backup_stow_conflicts() {
    local pkg="$1"
    local pkg_dir="$DOTFILES_DIR/$pkg"
    [ -d "$pkg_dir" ] || return 0
    local ts
    ts=$(date +%Y%m%d-%H%M%S)
    while IFS= read -r -d '' src; do
        local rel="${src#"$pkg_dir/"}"
        local target="$HOME/$rel"
        if [ -e "$target" ] && [ ! -L "$target" ] && [ ! -d "$target" ]; then
            echo "  backing up $target -> $target.bak.$ts"
            mv "$target" "$target.bak.$ts"
        fi
    done < <(find "$pkg_dir" -type f -print0)
}

stow_pkg() {
    backup_stow_conflicts "$1"
    stow --restow --no-folding --target="$HOME" "$1"
}

# --- Core prelude (always runs) ----------------------------------------

ensure_brew_on_path() {
    if command -v brew &>/dev/null; then return; fi
    if [ -x /opt/homebrew/bin/brew ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [ -x /usr/local/bin/brew ]; then
        eval "$(/usr/local/bin/brew shellenv)"
    else
        echo "Error: Homebrew is required. Install from https://brew.sh" >&2
        exit 1
    fi
}

install_core() {
    case "$OS" in
        Linux)
            sudo apt update
            # stow: linking configs. curl: nvm/claude/nvim tarball. git: plugin clones.
            sudo apt install -y curl git stow
            ;;
        Darwin)
            ensure_brew_on_path
            brew install stow
            ;;
        *)
            echo "Unsupported OS: $OS" >&2
            exit 1
            ;;
    esac
}

# --- zsh ---------------------------------------------------------------

install_zsh() {
    case "$OS" in
        Linux)
            sudo apt install -y zsh fzf
            user_shell=$(getent passwd "$USER" | cut -d: -f7)
            case "$user_shell" in
                */zsh) echo "Default shell is already zsh" ;;
                *)
                    echo "Setting default shell to zsh"
                    chsh -s "$(command -v zsh)"
                    ;;
            esac
            ;;
        Darwin)
            brew install fzf
            ;;
    esac
}

setup_zsh() {
    mkdir -p "$XDG_STATE_HOME/zsh" "$XDG_CACHE_HOME/zsh"
    stow_pkg zsh

    local plugin_dir="$XDG_DATA_HOME/zsh/plugins"
    mkdir -p "$plugin_dir"

    if [ ! -d "$plugin_dir/zsh-syntax-highlighting" ]; then
        echo "Installing zsh-syntax-highlighting..."
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git \
            "$plugin_dir/zsh-syntax-highlighting"
    else
        echo "zsh-syntax-highlighting already installed"
    fi

    if [ ! -d "$plugin_dir/catppuccin-zsh" ]; then
        echo "Installing catppuccin zsh theme..."
        git clone https://github.com/catppuccin/zsh-syntax-highlighting.git \
            "$plugin_dir/catppuccin-zsh"
    else
        echo "catppuccin-zsh already installed"
    fi
}

# --- nvim --------------------------------------------------------------

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

# Neovim plugins (lazy.nvim, blink.cmp, native inlay hints) require 0.10+.
require_nvim_010() {
    if ! command -v nvim >/dev/null; then
        echo "Error: nvim not found on PATH." >&2
        exit 1
    fi
    local version major minor
    version=$(nvim --version | head -1 | awk '{print $2}' | tr -d 'v')
    major=$(echo "$version" | cut -d. -f1)
    minor=$(echo "$version" | cut -d. -f2)
    if [ "$major" -eq 0 ] && [ "$minor" -lt 10 ]; then
        echo "Error: Neovim >= 0.10 required, found $version." >&2
        exit 1
    fi
}

install_nvim() {
    case "$OS" in
        Linux)
            # build-essential + cmake: Mason builds some tools from source.
            # ripgrep: Telescope live_grep. unzip: Mason archive extraction.
            # fd-find: Telescope file listing (binary is `fdfind` on apt).
            # clang-format: Mason's pypi provider rejects it (missing requires_python).
            sudo apt install -y build-essential cmake ripgrep unzip fd-find clang-format
            install_nvim_linux
            mkdir -p "$HOME/.local/bin"
            if command -v fdfind &>/dev/null && ! command -v fd &>/dev/null; then
                ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
            fi
            ;;
        Darwin)
            ensure_brew_on_path
            brew install neovim ripgrep fd cmake clang-format
            ;;
    esac
    require_nvim_010
}

setup_nvim() {
    stow_pkg nvim

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
    local spellfile="$HOME/.config/nvim/spell/en.utf-8.add"
    if [ -f "$spellfile" ]; then
        echo "Compiling spellfile..."
        nvim --headless "+silent! mkspell! $spellfile" +qa
    fi
}

# --- tmux --------------------------------------------------------------

install_tmux() {
    case "$OS" in
        Linux)  sudo apt install -y tmux ;;
        Darwin) brew install tmux ;;
    esac
}

setup_tmux() {
    stow_pkg tmux

    local tpm_dir="$XDG_DATA_HOME/tmux/plugins/tpm"
    if [ ! -d "$tpm_dir" ]; then
        echo "Installing tpm..."
        git clone https://github.com/tmux-plugins/tpm "$tpm_dir"
    else
        echo "tpm already installed"
    fi

    if [ -x "$tpm_dir/bin/install_plugins" ]; then
        echo "Installing tmux plugins..."
        "$tpm_dir/bin/install_plugins"
    fi
}

# --- git ---------------------------------------------------------------

install_git() {
    # git itself is part of install_core; nothing extra to install.
    :
}

setup_git() {
    stow_pkg git
}

# --- node (nvm + LTS) --------------------------------------------------

install_node() {
    export NVM_DIR="${XDG_DATA_HOME}/nvm"

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

setup_node() {
    :
}

# --- claude ------------------------------------------------------------

install_claude() {
    if command -v claude &>/dev/null; then
        echo "Claude Code already installed"
        return
    fi
    echo "Installing Claude Code..."
    # Pipe to bash, not sh — on Debian/Ubuntu /bin/sh is dash and the
    # installer uses bash-only syntax.
    curl -fsSL https://claude.ai/install.sh | bash
}

setup_claude() {
    :
}

# --- Argument parsing & dispatch ---------------------------------------

usage() {
    echo "Usage: $0 [component...]" >&2
    echo "Components: ${ALL_COMPONENTS[*]}" >&2
    echo "With no args, installs and configures all components." >&2
    exit 2
}

parse_args() {
    if [ $# -eq 0 ]; then
        for c in "${ALL_COMPONENTS[@]}"; do select_component "$c"; done
        return
    fi
    for arg in "$@"; do
        case "$arg" in
            -h|--help) usage ;;
        esac
        local found=0
        for c in "${ALL_COMPONENTS[@]}"; do
            if [ "$arg" = "$c" ]; then found=1; break; fi
        done
        if [ "$found" = 0 ]; then
            echo "Unknown component: $arg" >&2
            usage
        fi
        select_component "$arg"
    done
}

resolve_dependencies() {
    # nvim's Mason needs node on PATH at setup time.
    if is_selected nvim; then select_component node; fi
}

main() {
    parse_args "$@"
    resolve_dependencies

    echo "Components selected:$SELECTED"

    install_core

    # Install everything before any setup, so deps (e.g. node) are on PATH
    # before dependent setup steps (e.g. nvim's Mason) run.
    for c in "${ALL_COMPONENTS[@]}"; do
        if is_selected "$c"; then
            echo "==> install $c"
            "install_$c"
        fi
    done

    for c in "${ALL_COMPONENTS[@]}"; do
        if is_selected "$c"; then
            echo "==> setup $c"
            "setup_$c"
        fi
    done

    echo "Bootstrap complete."
}

main "$@"
