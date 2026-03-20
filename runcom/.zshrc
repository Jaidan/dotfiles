# oh-my-zsh
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="agnoster"
# Build plugins list — only include tmux if it is installed
plugins=(git docker python virtualenv)
command -v tmux &>/dev/null && plugins+=(tmux)

# ── PATH ──────────────────────────────────────────────────────────────────────
export PATH="$HOME/bin:$HOME/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

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

# ── agnoster theme — hide user@host when logged in as yourself ────────────────
export DEFAULT_USER="${USER}"

source "$ZSH/oh-my-zsh.sh"

# ── Aliases ───────────────────────────────────────────────────────────────────
[ -f ~/.aliases ] && source ~/.aliases

# ── fzf ───────────────────────────────────────────────────────────────────────
export FZF_DEFAULT_COMMAND='(git ls-files || find . -path "*/\.*" -prune -o -type f -print -o -type l -print) 2>/dev/null'
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# ── NVM ───────────────────────────────────────────────────────────────────────
export NVM_DIR="${XDG_CONFIG_HOME:-$HOME}/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"

# ── Machine-specific overrides (not tracked in git) ───────────────────────────
[ -f ~/.locals ] && source ~/.locals
