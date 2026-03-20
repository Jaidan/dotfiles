#!/usr/bin/env bash
# install.sh — bootstrap dotfiles on a new machine or Codespace
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OS="$(uname -s)"

# ── Logging ─────────────────────────────────────────────────────────────────

info()    { printf '\033[0;34m[info]\033[0m     %s\n' "$*"; }
success() { printf '\033[0;32m[ok]\033[0m       %s\n' "$*"; }
warning() { printf '\033[0;33m[warning]\033[0m  %s\n' "$*"; }
error()   { printf '\033[0;31m[error]\033[0m    %s\n' "$*" >&2; }

# ── Homebrew (macOS) ─────────────────────────────────────────────────────────

install_homebrew() {
  if command -v brew &>/dev/null; then
    info "Homebrew already installed — skipping"
    return
  fi
  info "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  # Add brew to PATH for Apple Silicon Macs
  if [[ -f /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi
  success "Homebrew installed"
}

install_brew_bundle() {
  info "Installing Homebrew packages..."
  brew bundle --file="$DOTFILES_DIR/install/Brewfile"
  success "Homebrew packages installed"
}

# ── apt packages (Linux / Codespaces) ────────────────────────────────────────

install_apt_deps() {
  info "Installing apt dependencies..."
  sudo apt-get update -qq
  sudo apt-get install -y -qq \
    git \
    stow \
    zsh \
    neovim \
    tmux \
    fzf \
    curl \
    build-essential
  success "apt packages installed"
}

# ── oh-my-zsh ────────────────────────────────────────────────────────────────

install_oh_my_zsh() {
  if [[ -d "$HOME/.oh-my-zsh" ]]; then
    info "oh-my-zsh already installed — skipping"
    return
  fi
  info "Installing oh-my-zsh..."
  # RUNZSH=no    — don't switch shell mid-install
  # KEEP_ZSHRC=yes — don't overwrite the .zshrc we're about to symlink
  RUNZSH=no KEEP_ZSHRC=yes \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  success "oh-my-zsh installed"
}

# ── fzf shell integration ─────────────────────────────────────────────────────

setup_fzf() {
  local fzf_install=""
  if command -v brew &>/dev/null; then
    fzf_install="$(brew --prefix fzf 2>/dev/null)/install" || true
  fi
  [[ -z "$fzf_install" ]] && fzf_install="$HOME/.fzf/install"

  if [[ -x "$fzf_install" ]]; then
    info "Setting up fzf shell integration..."
    "$fzf_install" --all --no-update-rc
    success "fzf shell integration installed"
  fi
}

# ── Stow ─────────────────────────────────────────────────────────────────────

backup_conflicts() {
  local pkg="$1"
  local target_dir="$2"
  local backup_dir="$3"

  # Stow links top-level items; back up any real files/dirs at those paths
  for item in "$DOTFILES_DIR/$pkg"/.[!.]* "$DOTFILES_DIR/$pkg"/*; do
    [[ -e "$item" ]] || continue
    local name
    name="$(basename "$item")"
    local target="$target_dir/$name"
    if [[ -e "$target" && ! -L "$target" ]]; then
      mkdir -p "$backup_dir"
      mv "$target" "$backup_dir/"
      warning "  Backed up existing: ~/${name}"
    fi
  done
}

link_dotfiles() {
  info "Linking dotfiles with stow..."
  cd "$DOTFILES_DIR"

  local backup_dir="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"
  local home_packages=(git runcom shell tmux vim)
  local config_package=config

  # Back up any pre-existing real files that stow would conflict with
  for pkg in "${home_packages[@]}"; do
    backup_conflicts "$pkg" "$HOME" "$backup_dir"
  done
  backup_conflicts "$config_package" "$HOME/.config" "$backup_dir"

  mkdir -p "$HOME/.config"
  stow --restow --dir="$DOTFILES_DIR" --target="$HOME"         "${home_packages[@]}"
  stow --restow --dir="$DOTFILES_DIR" --target="$HOME/.config" "$config_package"
  success "Dotfiles linked"
}

# ── Default shell ─────────────────────────────────────────────────────────────

setup_zsh() {
  if [[ "$SHELL" == */zsh ]]; then
    info "zsh is already the default shell — skipping"
    return
  fi
  local zsh_path
  zsh_path="$(command -v zsh)"
  if grep -qF "$zsh_path" /etc/shells 2>/dev/null; then
    info "Setting default shell to zsh..."
    if chsh -s "$zsh_path" 2>/dev/null; then
      success "Default shell set to zsh"
    else
      warning "chsh failed (PAM/container?) — run manually: chsh -s $zsh_path"
    fi
  else
    warning "zsh not in /etc/shells — run manually: chsh -s $zsh_path"
  fi
}

# ── Main ──────────────────────────────────────────────────────────────────────

main() {
  info "Dotfiles: $DOTFILES_DIR"
  info "OS:       $OS"
  echo

  case "$OS" in
    Darwin)
      install_homebrew
      install_brew_bundle
      install_oh_my_zsh
      setup_fzf
      link_dotfiles
      ;;
    Linux)
      install_apt_deps
      install_oh_my_zsh
      setup_fzf
      link_dotfiles
      # Skip chsh in Codespaces — default shell is set via devcontainer.json
      [[ "${CODESPACES:-}" != "true" ]] && setup_zsh
      ;;
    *)
      error "Unsupported OS: $OS"
      exit 1
      ;;
  esac

  echo
  success "All done! Open a new shell or run: source ~/.zshrc"
}

main "$@"
