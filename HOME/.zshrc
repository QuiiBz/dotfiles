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

# Paths
export PATH="/Users/tom/Library/Python/3.10/bin:$PATH"
export PROTO_HOME="$HOME/.proto"
export PATH="$PROTO_HOME/shims:$PROTO_HOME/bin:$PATH"
export GOBIN="$HOME/go/bin"
export PATH="$GOBIN:$PATH"
export PATH="$HOME/.turso:$PATH"
export WASMTIME_HOME="$HOME/.wasmtime"
export PATH="$WASMTIME_HOME/bin:$PATH"
export PATH=/Users/tom/.sst/bin:$PATH

# Configurations
export RUSTC_WRAPPER="/opt/homebrew/bin/sccache"
export FORCE_COLOR=1 # Enable Turborepo colors
export LC_ALL=en_US.UTF-8
export FZF_DEFAULT_OPTS=" \
--color=bg+:#363a4f,bg:#24273a,spinner:#f4dbd6,hl:#ed8796 \
--color=fg:#cad3f5,header:#ed8796,info:#c6a0f6,pointer:#f4dbd6 \
--color=marker:#f4dbd6,fg+:#cad3f5,prompt:#c6a0f6,hl+:#ed8796"
export TERM=xterm-256color

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

eval "$(fzf --zsh)"
eval "$(starship init zsh)"

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
zstyle ':completion:*:*:*:*:*' menu select
zmodload zsh/complist
zstyle ':completion:*' special-dirs true
zstyle ':completion:*' list-colors ''
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#) ([0-9a-z-]#)*=01;34=0=01'
zstyle ':completion:*:cd:*' tag-order local-directories directory-stack path-directories
zstyle ':completion:*' use-cache yes
zstyle ':completion:*' cache-path $ZSH_CACHE_DIR
bindkey -M menuselect '^[[Z' reverse-menu-complete
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
