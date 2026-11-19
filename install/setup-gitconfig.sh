#!/usr/bin/env bash
# setup-gitconfig.sh — make ~/.gitconfig a real per-machine file that includes
# the tracked ~/.gitconfig.shared.
#
# Why not stow ~/.gitconfig directly: every `git config --global` write
# (`gh auth setup-git`, VS Code's credential helper, Coder) follows the symlink
# and lands machine-specific paths in the repo. And Roverspaces/Codespaces
# pre-populate ~/.gitconfig with their own credential setup, which a symlink
# would clobber. So the tracked file holds only portable settings, and each
# machine keeps its own ~/.gitconfig with an [include] at the top — later
# entries in the local file (credential helpers, editor overrides) win.
#
# Idempotent. Migrates the old layout (~/.gitconfig symlinked into the repo)
# by carrying its credential.* entries over to the new real file.
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GITCONFIG="$HOME/.gitconfig"
INCLUDE_PATH="~/.gitconfig.shared"

if [[ -L "$GITCONFIG" ]]; then
  old="$(readlink "$GITCONFIG")"
  [[ "$old" == /* ]] || old="$HOME/$old"
  # The old link target was git/.gitconfig, renamed to .gitconfig.shared
  [[ -f "$old" ]] || old="$DOTFILES_DIR/git/.gitconfig.shared"
  tmp="$(mktemp)"
  if [[ -f "$old" ]]; then
    # Carry over machine-local credential helpers (preserves empty `helper =`
    # resets, which must precede the real helper).
    git config --file "$old" --get-regexp '^credential\.' 2>/dev/null \
      | while read -r key value; do
          git config --file "$tmp" --add "$key" "${value:-}"
        done || true
  fi
  rm "$GITCONFIG"
  mv "$tmp" "$GITCONFIG"
  echo "Replaced ~/.gitconfig symlink with a real file (kept credential.* entries)"
fi

touch "$GITCONFIG"
if ! git config --file "$GITCONFIG" --get-all include.path 2>/dev/null | grep -qxF "$INCLUDE_PATH"; then
  # Prepend, so anything already in the local file overrides the shared base.
  tmp="$(mktemp)"
  { printf '[include]\n\tpath = %s\n' "$INCLUDE_PATH"; cat "$GITCONFIG"; } > "$tmp"
  cat "$tmp" > "$GITCONFIG"
  rm -f "$tmp"
  echo "Added [include] path = $INCLUDE_PATH to ~/.gitconfig"
fi

