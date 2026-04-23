# ~/.zshenv
# Minimal bootstrap for all ZSH shells. Sets ZDOTDIR and XDG base directories.

export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"

# XDG compliance for tools that honor env vars but not the spec by default.
export LESSHISTFILE="$XDG_STATE_HOME/less/history"
export PYTHON_HISTORY="$XDG_STATE_HOME/python/history"
export NODE_REPL_HISTORY="$XDG_STATE_HOME/node/repl_history"
export npm_config_cache="$XDG_CACHE_HOME/npm"

export ZDOTDIR="$XDG_CONFIG_HOME/zsh"

export GOPATH="$HOME/go"
export PATH="$HOME/.local/bin:$HOME/bin:$GOPATH/bin:$PATH"
