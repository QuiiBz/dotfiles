# Enable profiling
# zmodload zsh/zprof

# Aliases
alias vim="nvim"
alias ls="eza"
alias ll="eza -lh"
alias l="eza -lah"
alias cat="bat"
alias luamake=/Users/tom/dev/lua-language-server/3rd/luamake/luamake
alias flushdns="sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder"
alias pnpx="pnpm dlx"
alias lg="lazygit"
alias k="kubectl"
alias kk6='kubectl -n k6-operator-system'
alias tf="terraform"
alias ts="tailscale"
alias home="~/home.sh"
alias sync="~/sync.sh"

# Paths
export PATH="/Users/tom/Library/Python/3.10/bin:$PATH"
export PROTO_HOME="$HOME/.proto"
export PATH="$PROTO_HOME/shims:$PROTO_HOME/bin:$PATH"
export GOBIN="$HOME/go/bin"
export PATH="$GOBIN:$PATH"
export PATH=/Users/tom/.opencode/bin:$PATH
export PATH="$PATH:/Users/tom/.lmstudio/bin"

# Configurations
export RUSTC_WRAPPER="/opt/homebrew/bin/sccache"
export FORCE_COLOR=1 # Enable Turborepo colors
export LC_ALL=en_US.UTF-8
export FZF_DEFAULT_OPTS=" \
--color=bg+:-1,bg:-1,spinner:#F4DBD6,hl:#ED8796 \
--color=fg:#CAD3F5,header:#ED8796,info:#C6A0F6,pointer:#F4DBD6 \
--color=marker:#B7BDF8,fg+:#CAD3F5,prompt:#C6A0F6,hl+:#ED8796 \
--color=selected-bg:#494D64 \
--color=border:#6E738D,label:#CAD3F5"
export TERM=xterm-256color
export XDG_CONFIG_HOME="$HOME/.config"
export HOMEBREW_NO_AUTO_UPDATE=1
export ZSH_AUTOSUGGEST_USE_ASYNC=1
export PURE_GIT_DOWN_ARROW='↓'
export PURE_GIT_UP_ARROW='↑'
export MANPAGER="sh -c 'awk '\''{ gsub(/\x1B\[[0-9;]*m/, \"\", \$0); gsub(/.\x08/, \"\", \$0); print }'\'' | bat -p -lman'"
export BAT_STYLE="plain"

# PNPM
export PNPM_HOME="/Users/tom/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

# Check if 'kubectl' is a command in $PATH
if [ $commands[kubectl] ]; then
  # Placeholder 'kubectl' shell function:
  # Will only be executed on the first call to 'kubectl'
  kubectl() {
    # Remove this function, subsequent calls will execute 'kubectl' directly
    unfunction "$0"
    # Load auto-completion
    source <(kubectl completion zsh)
    # Execute 'kubectl' binary
    $0 "$@"
  }
fi

autoload -U promptinit; promptinit
prompt pure

# ZSH settings
bindkey "\e[1;3D" backward-word
bindkey "\e[1;3C" forward-word
bindkey "\e[1;2D" backward-word
bindkey "\e[1;2C" forward-word
WORDCHARS=''
setopt menu_complete
setopt auto_menu
setopt complete_in_word
setopt always_to_end
setopt SHARE_HISTORY       # Share command history data
setopt INC_APPEND_HISTORY  # Append to history file immediately
setopt HIST_FIND_NO_DUPS   # Avoid duplicates in searches
setopt HIST_IGNORE_ALL_DUPS # Remove older duplicates
zstyle ':completion:*:*:*:*:*' menu select
zmodload zsh/complist
zstyle ':completion:*' special-dirs true
zstyle ':completion:*' list-colors ''
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#) ([0-9a-z-]#)*=01;34=0=01'
zstyle ':completion:*:cd:*' tag-order local-directories directory-stack path-directories
zstyle ':completion:*' use-cache yes
zstyle ':completion:*' cache-path $ZSH_CACHE_DIR
zstyle ':prompt:pure:path' color 'cyan'
zstyle ':prompt:pure:prompt:success' color 'green'
zstyle ':prompt:pure:git:branch' color 'magenta'
zstyle ':prompt:pure:git:dirty' color 'magenta'
zstyle ':prompt:pure:git:arrow' color 'red'

# Ctrl+R history search via fzf
fzf-history-widget() {
  local selected
  selected=$(
    tac "$HISTFILE" \
    | LC_ALL=C sed -E 's/^: [0-9]+:[0-9]+;//' \
    | awk '!seen[$0]++' \
    | fzf --height 40% --no-border --prompt="> " --no-sort --query="$LBUFFER"
  )
  if [[ -n $selected ]]; then
    BUFFER=$selected
    CURSOR=${#BUFFER}
  fi
  zle reset-prompt
}
zle     -N   fzf-history-widget
bindkey '^R' fzf-history-widget

autoload -Uz compinit
for dump in ~/.zcompdump(N.mh+24); do
  compinit
done
compinit -C

# Plugins
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Enable profiling
# zprof
