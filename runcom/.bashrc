# .bashrc — sourced for interactive bash shells (macOS + Linux)
[ -z "$PS1" ] && return

# ── History ───────────────────────────────────────────────────────────────────
export HISTCONTROL=ignoreboth
export HISTSIZE=10000
export HISTFILESIZE=20000
shopt -s histappend
shopt -s checkwinsize

# ── Completion ────────────────────────────────────────────────────────────────
if command -v brew &>/dev/null; then
  BREW_PREFIX="$(brew --prefix)"
  [ -f "$BREW_PREFIX/etc/bash_completion" ] && source "$BREW_PREFIX/etc/bash_completion"
elif [ -f /etc/bash_completion ]; then
  source /etc/bash_completion
fi

# ── PATH ──────────────────────────────────────────────────────────────────────
export PATH="$HOME/bin:/usr/local/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

# pyenv
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
if command -v pyenv &>/dev/null; then
  eval "$(pyenv init -)"
  eval "$(pyenv virtualenv-init -)"
fi

# ── Editor ────────────────────────────────────────────────────────────────────
export EDITOR="nvim"
export VISUAL="$EDITOR"
export CLICOLOR=1

# ── Prompt ────────────────────────────────────────────────────────────────────
# Load git prompt support (brew on macOS, fallback to ~/.git-prompt.sh on Linux)
if command -v brew &>/dev/null; then
  GIT_PROMPT_SH="$(brew --prefix)/etc/bash_completion.d/git-prompt.sh"
  [ -f "$GIT_PROMPT_SH" ] && source "$GIT_PROMPT_SH"
fi
[ -f ~/.git-prompt.sh ] && source ~/.git-prompt.sh

_set_prompt() {
  local GREEN=$'\e[1;32m'
  local MAGENTA=$'\e[1;35m'
  local RESET=$'\e[m'
  PS1="\[$RESET\]\u@\h:\[$GREEN\]\w\[$MAGENTA\]\$(__git_ps1 ' (%s)')\[$RESET\]\$ "
  PS2='> '
}
_set_prompt

# ── Aliases ───────────────────────────────────────────────────────────────────
[ -f ~/.aliases ] && source ~/.aliases

# ── fzf ───────────────────────────────────────────────────────────────────────
export FZF_DEFAULT_COMMAND='(git ls-files || find . -path "*/\.*" -prune -o -type f -print -o -type l -print) 2>/dev/null'
[ -f ~/.fzf.bash ] && source ~/.fzf.bash

# ── NVM ───────────────────────────────────────────────────────────────────────
export NVM_DIR="${XDG_CONFIG_HOME:-$HOME}/.nvm"
[ -s "$NVM_DIR/nvm.sh" ]          && source "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && source "$NVM_DIR/bash_completion"

# ── Machine-specific overrides (not tracked in git) ───────────────────────────
[ -f ~/.local ] && source ~/.local
