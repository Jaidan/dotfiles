# oh-my-zsh
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="agnoster"
# Build plugins list — only include tmux if it is installed
plugins=(git docker python virtualenv)
command -v tmux &>/dev/null && plugins+=(tmux)

# ── PATH ──────────────────────────────────────────────────────────────────────
# Prepend personal dirs; preserve whatever the system/Codespace already set
export PATH="$HOME/bin:$HOME/.local/bin:/snap/bin:$PATH"

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
[[ -t 0 && -t 1 ]] && [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

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

# ── dotfiles: auto-update from git on new shells (throttled, backgrounded) ────
# Set DOTFILES_NO_AUTOUPDATE=1 (e.g. in ~/.locals) to disable. Override the repo
# location with DOTFILES_DIR if you cloned somewhere other than ~/dotfiles.
_dotfiles_pull() {
  # Fast-forward pull, only when the tree is clean; leave a notice if HEAD moved.
  local repo="$1" notice="$2"
  [ -n "$(git -C "$repo" status --porcelain 2>/dev/null)" ] && return 0
  local before after
  before=$(git -C "$repo" rev-parse HEAD 2>/dev/null) || return 0
  git -C "$repo" pull --ff-only --quiet 2>/dev/null || return 0
  after=$(git -C "$repo" rev-parse HEAD 2>/dev/null)
  [ "$before" = "$after" ] && return 0
  local n
  n=$(git -C "$repo" rev-list --count "$before..$after" 2>/dev/null)
  printf 'dotfiles: pulled %s new commit(s). Symlinked files are already live; run `make link` if new files were added.\n' "$n" > "$notice"
}
_dotfiles_autoupdate() {
  [ -n "${DOTFILES_NO_AUTOUPDATE:-}" ] && return 0
  local repo="${DOTFILES_DIR:-$HOME/dotfiles}"
  local notice="$HOME/.cache/dotfiles-update.notice"
  # Phase 1: surface the result of any prior background pull.
  if [ -s "$notice" ]; then
    cat "$notice"
    rm -f "$notice"
  fi
  [ -d "$repo/.git" ] || return 0
  # Phase 2: kick off a background pull at most once per day.
  local stamp="$HOME/.cache/dotfiles-update.stamp"
  mkdir -p "$(dirname "$stamp")"
  local now last=0
  now=$(date +%s)
  [ -f "$stamp" ] && last=$(cat "$stamp" 2>/dev/null || echo 0)
  (( now - last < 86400 )) && return 0
  echo "$now" > "$stamp"  # stamp first so an offline shell won't retry every prompt
  ( _dotfiles_pull "$repo" "$notice" >/dev/null 2>&1 &! ) 2>/dev/null
}
add-zsh-hook precmd _dotfiles_autoupdate

# ── Machine-specific overrides (not tracked in git) ───────────────────────────
[ -f ~/.locals ] && source ~/.locals

