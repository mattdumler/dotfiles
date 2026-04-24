# ZSH configuration for login shells.

export PAGER="less"
export LESS="-R"

# Preferred editor.
export EDITOR='nvim'
export VISUAL='nvim'

# Use the Homebrew package manager.
if [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi
