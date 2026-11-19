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

### Connecting a Codespace to herdr

From the Mac, run:

```bash
cs-herdr            # pick a codespace (fzf if there's more than one)
cs-herdr -f <name>  # re-add one after a rebuild
```

It regenerates `~/.ssh/codespaces` (each codespace gets its bare name as an SSH alias), refreshes the host key, adds the codespace to herdr as `cs-<repo>-<display-name>`, and removes herdr machines for deleted codespaces. It needs `gh` authenticated with the `codespace` scope (`gh auth refresh -h github.com -s codespace`).

## Roverspaces (Coder)

Roverspaces run this repo through Coder's dotfiles integration: it's cloned to `~/.config/coderv2/dotfiles` and `install.sh` runs non-interactively on every workspace start (home isn't persistent). When `CODER=true`, `install.sh`:

- **appends** a `source` line for our `.zshrc` to Rover's `~/.zshrc` instead of replacing it. Rover's `onCreateCommand` puts the venv, `./profile`, `rover-cli` and OTel creds there and asks dotfiles not to overwrite it. `~/.bashrc` is left to Rover entirely. Only `.zshenv` is symlinked.
- skips the Claude config, because Roverspaces use a Rover-managed `CLAUDE_CONFIG_DIR`.
- installs herdr right after apt, so a later failure can't leave the box without it.

Every Linux step is isolated: a failure is reported, the rest still run, and the script exits non-zero at the end. Test the Roverspace path with `docker compose -f docker-compose.test.yml run --rm install-coder`.

### git config layout

`~/.gitconfig` is a **real per-machine file**. The tracked settings live in `git/.gitconfig.shared`, linked to `~/.gitconfig.shared` and pulled in by an `[include]` at the top of `~/.gitconfig` (`install/setup-gitconfig.sh`, idempotent, also run by `make link`). Credential helpers and other machine-specific entries stay in `~/.gitconfig`, so `gh auth setup-git`, Codespaces and Coder never write into the repo. `git config --global --get` doesn't follow includes; use `git config --get`.

## Structure

Each top-level directory is a [GNU Stow](https://www.gnu.org/software/stow/) package that mirrors `$HOME`.

```
.devcontainer/       Codespaces container config
bin/                 → ~/.local/bin/  (personal scripts, file-level links — e.g. cs-herdr)
claude/              → ~/.claude/  (statusline scripts; settings merged, not linked)
config/              → ~/.config/  (nvim)
git/                 → ~/          (.gitconfig.shared, .gitignore, .git_template/; ~/.gitconfig stays a real file)
herdr/               → ~/.config/herdr/config.toml  (file-level link; runtime dir untracked)
install/             Brewfile, herdr-plugins.txt
iterm/               iTerm2 config (import via iTerm Preferences → General)
macos/               macOS system defaults script
runcom/              → ~/          (.zshrc, .zshenv, .bashrc, .bash_profile)
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
make claude    # Link Claude statusline + merge base settings
make herdr     # Link herdr config.toml
make bin       # Link scripts into ~/.local/bin
make update    # git pull + re-link
```

## Claude Code config

The `claude/` package tracks the Claude Code status line and a portable base of
settings. `~/.claude/` is a live runtime directory (credentials, history,
sessions), so only two things are managed:

- **Statusline script** (`statusline.sh`) is symlinked into `~/.claude/` via
  stow. It shows model, git branch, effort, and worktree on line one; context
  window and rate limits on line two. Branch names matching `<PREFIX>-<number>`
  become clickable Linear issue links. Which org and prefix vary per project,
  so they're configured in that project's `.claude/settings.json` (commit it to
  share the config with the repo) or `.claude/settings.local.json` (keep it to
  yourself):

  ```json
  {
    "env": {
      "CLAUDE_STATUSLINE_LINEAR_ORG": "acme",
      "CLAUDE_STATUSLINE_TICKET_PREFIX": "ACME"
    }
  }
  ```

  Both are optional and unset globally. Projects that don't define them render
  branches as plain text — nothing to configure for the statusline to work.

- **Base settings** live in `install/claude-settings.base.json` and are *merged*
  over the live `~/.claude/settings.json` with `jq` (via `make claude` or the
  installer). Only portable keys are set (status line, theme, editor mode, …);
  machine- and work-specific keys (`model`, `enabledPlugins`, …) are left
  untouched. Settings are merged rather than symlinked because Claude Code
  rewrites `settings.json` at runtime.

## Auto-update on new shells

Both `.zshrc` and `.bashrc` run a throttled, backgrounded `git pull --ff-only`
of `~/dotfiles` once per day, but only when the working tree is clean. If new
commits arrive, a short notice prints in the next shell. Symlinked files update
immediately; run `make link` only if new files were added. Set
`DOTFILES_NO_AUTOUPDATE=1` (e.g. in `~/.locals`) to disable it.

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
