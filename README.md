# dotfiles

Personal dotfiles for macOS, managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Fresh install

```sh
git clone git@github.com:Jaidan/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

`install.sh` will:
- **macOS** — install Homebrew, run `brew bundle`, install oh-my-zsh, set up fzf, and stow all packages
- **Linux / Codespaces** — install core apt deps, install oh-my-zsh, set up fzf, stow all packages, and set zsh as the default shell

Existing dotfiles that would conflict are automatically backed up to `~/.dotfiles-backup-<date>` before stowing.

## Terminal font

The zsh theme (agnoster) uses Powerline symbols. `brew bundle` installs **MesloLGS Nerd Font** automatically, but you still need to tell your terminal to use it:

- **iTerm2** — Preferences → Profiles → Text → Font → pick `MesloLGS NF`
- **Terminal.app** — Settings → Profiles → Font → pick `MesloLGS NF`
- **VS Code terminal** — add to `settings.json`: `"terminal.integrated.fontFamily": "MesloLGS NF"`

## Codespaces

The [GitHub Codespaces dotfiles feature](https://docs.github.com/en/codespaces/setting-your-user-preferences/personalizing-github-codespaces-for-your-account#dotfiles) will automatically clone this repo and run `install.sh` in every new Codespace.

Enable it at: **github.com/settings/codespaces → Dotfiles**

## Structure

Each top-level directory is a [GNU Stow](https://www.gnu.org/software/stow/) package that mirrors `$HOME`.

```
.devcontainer/       Codespaces container config
config/              → ~/.config/  (nvim)
git/                 → ~/          (.gitconfig, .gitignore, .git_template/)
install/             Brewfile
iterm/               iTerm2 config (import via iTerm Preferences → General)
macos/               macOS system defaults script
runcom/              → ~/          (.zshrc, .bashrc, .bash_profile)
shell/               → ~/          (.aliases, .colordiffrc)
tmux/                → ~/          (.tmux.conf)
vim/                 → ~/          (.vimrc, .vim/)
Makefile
install.sh
```

## Testing the install

A Docker Compose setup lets you verify `install.sh` works end-to-end in a clean Ubuntu container (requires [Docker Desktop](https://www.docker.com/products/docker-desktop/)).

```sh
# Run install.sh to completion — exit 0 means success
docker compose -f docker-compose.test.yml run --rm install

# Run install.sh then drop into the resulting zsh environment
docker compose -f docker-compose.test.yml run --rm shell
```

The container starts from `ubuntu:24.04` with only `sudo` and `curl` pre-installed, so `install.sh` exercises the full Linux dependency path.

## Make targets

```sh
make install   # Full install: brew bundle + stow
make link      # Stow all packages into $HOME
make unlink    # Remove all stow symlinks
make brew      # Install/update Homebrew packages
make macos     # Apply macOS system preferences
make update    # git pull + re-link
```

## Machine-specific config

Anything that shouldn't be committed — tokens, work-specific env vars, machine-local paths — goes in `~/.locals`. It's sourced at the end of both `.zshrc` and `.bashrc`, and is gitignored.

```sh
# ~/.locals — not tracked in git
export HOMEBREW_GITHUB_API_TOKEN="..."
export ANDROID_HOME="$HOME/Library/Android/sdk"
export JAVA_HOME="/Applications/Android Studio.app/Contents/jre/jdk/Contents/Home"
export PATH="$PATH:$ANDROID_HOME/platform-tools"
source ~/.rover-ro
```

## Dependencies

Managed via `install/Brewfile`. Run `make brew` to install or update.

| Tool | Purpose |
|---|---|
| `stow` | Symlink manager |
| `neovim` | Editor |
| `tmux` | Terminal multiplexer |
| `fzf` | Fuzzy finder |
| `gh` | GitHub CLI |
| `universal-ctags` | Code navigation |
| `pyenv` + `pyenv-virtualenv` | Python version management |
| `nvm` | Node version management |
| `colordiff` | Coloured diff output |
