# .zshenv — sourced by every zsh, including non-interactive `ssh host cmd`.
#
# Keep this tiny. It exists for tools that ssh in and run commands without an
# interactive shell (herdr's remote bridge checks that `herdr` resolves to
# ~/.local/bin/herdr), which never see the PATH set up in .zshrc.

typeset -U path
path=("$HOME/.local/bin" $path)
