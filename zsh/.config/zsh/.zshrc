# Run commands for configuring interactive, non-login shells.

# Catppuccin Mocha palette
local -A CTP
CTP[rosewater]="#f5e0dc"
CTP[flamingo]="#f2cdcd"
CTP[pink]="#f5c2e7"
CTP[mauve]="#cba6f7"
CTP[red]="#f38ba8"
CTP[maroon]="#eba0ac"
CTP[peach]="#fab387"
CTP[yellow]="#f9e2af"
CTP[green]="#a6e3a1"
CTP[teal]="#94e2d5"
CTP[sky]="#89dceb"
CTP[sapphire]="#74c7ec"
CTP[blue]="#89b4fa"
CTP[lavender]="#b4befe"
CTP[text]="#cdd6f4"
CTP[subtext1]="#bac2de"
CTP[subtext0]="#a6adc8"
CTP[overlay2]="#9399b2"
CTP[overlay1]="#7f849c"
CTP[overlay0]="#6c7086"
CTP[surface2]="#585b70"
CTP[surface1]="#45475a"
CTP[surface0]="#313244"
CTP[base]="#1e1e2e"
CTP[mantle]="#181825"
CTP[crust]="#11111b"

# History
HISTFILE="${XDG_STATE_HOME}/zsh/history"
HISTSIZE=50000
SAVEHIST=50000

setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_REDUCE_BLANKS
setopt HIST_VERIFY
setopt EXTENDED_HISTORY

# Directory navigation
setopt AUTO_CD
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS
setopt PUSHD_SILENT

# General behavior
setopt CORRECT
setopt EXTENDED_GLOB
setopt INTERACTIVE_COMMENTS
setopt NO_BEEP
setopt PROMPT_SUBST

# Completion
autoload -Uz compinit && compinit -d "${XDG_CACHE_HOME}/zsh/zcompdump-${HOST}"

zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format "%F{${CTP[mauve]}}%B%d%b%f"

# Git info in prompt (via vcs_info)
autoload -Uz vcs_info
zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:git:*' check-for-changes true
zstyle ':vcs_info:git:*' stagedstr   "%F{${CTP[green]}}●%f"
zstyle ':vcs_info:git:*' unstagedstr "%F{${CTP[yellow]}}●%f"
zstyle ':vcs_info:git:*' formats     " %F{${CTP[pink]}} %b%f%c%u"
zstyle ':vcs_info:git:*' actionformats " %F{${CTP[pink]}} %b%f|%F{${CTP[red]}}%a%f%c%u"

precmd() { vcs_info }

# Prompt
PROMPT='%F{${CTP[mauve]}}%n%f%F{${CTP[overlay1]}}@%m%f %F{${CTP[blue]}}%~%f${vcs_info_msg_0_}
%(?.%F{${CTP[green]}}.%F{${CTP[red]}})❯%f '

RPROMPT='%(?..%F{${CTP[red]}}✘ %?%f )%F{${CTP[overlay0]}}%*%f'

# Keybindings
bindkey -e
bindkey '^[[A' up-line-or-search
bindkey '^[[B' down-line-or-search
bindkey '^[[1;5C' forward-word
bindkey '^[[1;5D' backward-word

# fzf (Ctrl+R history, Ctrl+T files, Alt+C dirs)
if [ -f "${XDG_CONFIG_HOME}/fzf/fzf.zsh" ]; then
    source "${XDG_CONFIG_HOME}/fzf/fzf.zsh"
elif [ -f "${HOME}/.fzf.zsh" ]; then
    source "${HOME}/.fzf.zsh"
fi

export FZF_DEFAULT_OPTS="
  --color=bg+:${CTP[surface0]},bg:${CTP[base]},spinner:${CTP[rosewater]},hl:${CTP[red]}
  --color=fg:${CTP[text]},header:${CTP[red]},info:${CTP[mauve]},pointer:${CTP[rosewater]}
  --color=marker:${CTP[rosewater]},fg+:${CTP[text]},prompt:${CTP[mauve]},hl+:${CTP[red]}
  --color=border:${CTP[surface2]}"

# Personal aliases.
source "${ZDOTDIR}/.zsh_aliases"

# Layer-specific aliases (e.g. work, desktop).
[ -f "${ZDOTDIR}/.zsh_aliases.local" ] && source "${ZDOTDIR}/.zsh_aliases.local"

# Set any tokens from a file not in source control.
[ -f "${ZDOTDIR}/.zsh_tokens" ] && source "${ZDOTDIR}/.zsh_tokens"

# Enable themes.
# Syntax highlighting must be sourced last.
source "${XDG_DATA_HOME}/zsh/plugins/catppuccin-zsh/themes/catppuccin_mocha-zsh-syntax-highlighting.zsh"
source "${XDG_DATA_HOME}/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
