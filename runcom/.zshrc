# oh-my-zsh
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="agnoster"
# Build plugins list — only include tmux if it is installed
plugins=(git docker python virtualenv)
command -v tmux &>/dev/null && plugins+=(tmux)

# ── PATH ──────────────────────────────────────────────────────────────────────
# Prepend personal dirs; preserve whatever the system/Codespace already set
export PATH="$HOME/bin:$HOME/.local/bin:$PATH"

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
# ~/.nvm on macOS/standard Linux; /usr/local/share/nvm in Codespaces
export NVM_DIR="${XDG_CONFIG_HOME:-$HOME}/.nvm"
if [[ ! -s "$NVM_DIR/nvm.sh" && -s "/usr/local/share/nvm/nvm.sh" ]]; then
  NVM_DIR="/usr/local/share/nvm"
fi
[ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"

# ── direnv ────────────────────────────────────────────────────────────────────
command -v direnv &>/dev/null && eval "$(direnv hook zsh)"

# ── Project-local profile (Codespaces only) ───────────────────────────────────
# Rover (and similar projects) ship a ./profile that must be sourced.
# Restrict to Codespaces so arbitrary profile files are never auto-loaded locally.
if [[ -n "$CODESPACE_NAME" ]]; then
  _source_local_profile() { [[ -f "$PWD/profile" ]] && source "$PWD/profile"; }
  autoload -U add-zsh-hook
  add-zsh-hook chpwd _source_local_profile
  _source_local_profile
fi

# Added by flyctl installer
export FLYCTL_INSTALL="/home/codespace/.fly"
export PATH="$FLYCTL_INSTALL/bin:$PATH"

# ── mealplanner: auto-prune merged worktrees (rate-limited, backgrounded) ────
_mealplanner_prune_worktrees() {
  local repo="/workspaces/mealplanner"
  local stamp="$HOME/.cache/mealplanner-prune.stamp"
  [ -x "$repo/scripts/prune-merged-worktrees.sh" ] || return 0
  mkdir -p "$(dirname "$stamp")"
  local now last=0
  now=$(date +%s)
  [ -f "$stamp" ] && last=$(cat "$stamp" 2>/dev/null || echo 0)
  (( now - last < 1800 )) && return 0
  echo "$now" > "$stamp"
  ( "$repo/scripts/prune-merged-worktrees.sh" "$repo" >/dev/null 2>&1 &! ) 2>/dev/null
}
autoload -U add-zsh-hook
add-zsh-hook precmd _mealplanner_prune_worktrees

# ── Machine-specific overrides (not tracked in git) ───────────────────────────
[ -f ~/.locals ] && source ~/.locals
