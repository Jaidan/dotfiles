SHELL       := bash
.SHELLFLAGS := -euo pipefail -c
DOTFILES    := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

# Packages stowed into $HOME
HOME_PACKAGES  := git runcom shell tmux vim
# Packages stowed into $HOME/.config
CONFIG_PACKAGE := config

.DEFAULT_GOAL := help
.PHONY: help install link unlink brew macos update

help: ## Show available targets
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
	  awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2}'

install: brew link ## Full install: Homebrew packages + symlinks

link: ## Symlink dotfiles into $HOME via stow
	mkdir -p $(HOME)/.config
	stow --restow --dir=$(DOTFILES) --target=$(HOME)         $(HOME_PACKAGES)
	stow --restow --dir=$(DOTFILES) --target=$(HOME)/.config $(CONFIG_PACKAGE)

unlink: ## Remove stow symlinks from $HOME
	stow --delete --dir=$(DOTFILES) --target=$(HOME)         $(HOME_PACKAGES)
	stow --delete --dir=$(DOTFILES) --target=$(HOME)/.config $(CONFIG_PACKAGE)

brew: ## Install/update Homebrew packages from Brewfile
	brew bundle --file=$(DOTFILES)install/Brewfile

macos: ## Apply macOS system preferences
	bash $(DOTFILES)macos/defaults.sh

update: ## Pull latest dotfiles and re-link
	git -C $(DOTFILES) pull --ff-only
	$(MAKE) link
