# ZSH configuration for login shells.

export PAGER="less"
export LESS="-R"

# Preferred editor.
export EDITOR='nvim'
export VISUAL='nvim'

# Go environment variables.
export GOROOT="$HOME/.go"
export GOPATH="$HOME/go"
export PATH="$PATH:$GOROOT/bin"

# Use the Homebrew package manager.
if [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi
