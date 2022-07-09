# Fig pre block. Keep at the top of this file.
[[ -f "$HOME/.fig/shell/bashrc.pre.bash" ]] && . "$HOME/.fig/shell/bashrc.pre.bash"
alias vim="nvim"
alias ls="exa"
alias ll="exa -lh"
alias l="exa -lah"
alias cat="bat"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm

GREEN="\[\033[1;36m\]"
CYAN="\[\033[32m\]"
PURPLE="\[\033[35m\]"
RESET="\[\033[00m\]"

parse_git_branch() {
    git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/   \1/'
}

export PS1="$GREEN\w$PURPLE\$(parse_git_branch)\n\r${CYAN}❯ $RESET"
. "$HOME/.cargo/env"

# Fig post block. Keep at the bottom of this file.
[[ -f "$HOME/.fig/shell/bashrc.post.bash" ]] && . "$HOME/.fig/shell/bashrc.post.bash"
