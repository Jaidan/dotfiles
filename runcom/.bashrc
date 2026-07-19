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
export PATH="$HOME/bin:$HOME/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/snap/bin"

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
[ -t 0 ] && [ -t 1 ] && [ -f ~/.fzf.bash ] && source ~/.fzf.bash

# ── NVM ───────────────────────────────────────────────────────────────────────
export NVM_DIR="${XDG_CONFIG_HOME:-$HOME}/.nvm"
[ -s "$NVM_DIR/nvm.sh" ]          && source "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && source "$NVM_DIR/bash_completion"

# ── direnv ────────────────────────────────────────────────────────────────────
command -v direnv &>/dev/null && eval "$(direnv hook bash)"

# ── Project-local profile (Codespaces only) ───────────────────────────────────
if [[ -n "$CODESPACE_NAME" ]]; then
  _source_local_profile() { [[ -f "$PWD/profile" ]] && source "$PWD/profile"; }
  _source_local_profile
  cd() { builtin cd "$@" && _source_local_profile; }
fi

# ── auto-prune merged worktrees (rate-limited, backgrounded) ─────────────────
# Runs <repo>/scripts/prune-merged-worktrees.sh for whichever repo the shell is
# currently in, at most once every 30 minutes per repo. Repos that don't ship
# that script return early, so this is inert everywhere else.
prune_worktrees() {
  local repo
  repo=$(git rev-parse --show-toplevel 2>/dev/null) || return 0
  local script="$repo/scripts/prune-merged-worktrees.sh"
  [ -x "$script" ] || return 0
  local stamp="$HOME/.cache/prune-worktrees/${repo//\//_}.stamp"
  mkdir -p "$(dirname "$stamp")"
  local now last=0
  now=$(date +%s)
  [ -f "$stamp" ] && last=$(cat "$stamp" 2>/dev/null || echo 0)
  (( now - last < 1800 )) && return 0
  echo "$now" > "$stamp"
  ( "$script" "$repo" >/dev/null 2>&1 & disown ) 2>/dev/null
}
case "${PROMPT_COMMAND:-}" in
  *prune_worktrees*) ;;
  *) PROMPT_COMMAND="prune_worktrees;${PROMPT_COMMAND:-}" ;;
esac

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
  ( _dotfiles_pull "$repo" "$notice" >/dev/null 2>&1 & disown ) 2>/dev/null
}
case "${PROMPT_COMMAND:-}" in
  *_dotfiles_autoupdate*) ;;
  *) PROMPT_COMMAND="_dotfiles_autoupdate;${PROMPT_COMMAND:-}" ;;
esac

# ── Machine-specific overrides (not tracked in git) ───────────────────────────
[ -f ~/.locals ] && source ~/.locals

# Added by flyctl installer
export FLYCTL_INSTALL="/home/codespace/.fly"
export PATH="$FLYCTL_INSTALL/bin:$PATH"
export PATH="$HOME/flutter/bin:$PATH"
