
#### FIG ENV VARIABLES ####
# Please make sure this block is at the start of this file.
[ -s ~/.fig/shell/pre.sh ] && source ~/.fig/shell/pre.sh
#### END FIG ENV VARIABLES ####

#### FIG ENV VARIABLES ####
# Please make sure this block is at the end of this file.
[ -s ~/.fig/fig.sh ] && source ~/.fig/fig.sh
#### END FIG ENV VARIABLES ####

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
