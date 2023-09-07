# Fig pre block. Keep at the top of this file.
[[ -f "$HOME/.fig/shell/bashrc.pre.bash" ]] && builtin source "$HOME/.fig/shell/bashrc.pre.bash"
alias vim="nvim"
alias ls="eza"
alias ll="eza -lh"
alias l="eza -lah"
alias cat="bat"

GREEN="\[\033[1;36m\]"
CYAN="\[\033[32m\]"
PURPLE="\[\033[35m\]"
RESET="\[\033[00m\]"

parse_git_branch() {
    git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/   \1/'
}

export PS1="$GREEN\w$PURPLE\$(parse_git_branch)\n\r${CYAN}❯ $RESET"

# Fig post block. Keep at the bottom of this file.
[[ -f "$HOME/.fig/shell/bashrc.post.bash" ]] && builtin source "$HOME/.fig/shell/bashrc.post.bash"
. "$HOME/.cargo/env"
