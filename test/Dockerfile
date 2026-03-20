FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# Install only the minimum needed for install.sh to start.
# Everything else (stow, zsh, neovim, tmux, fzf, ...) is installed by install.sh itself.
RUN apt-get update -qq && \
    apt-get install -y -qq sudo curl && \
    rm -rf /var/lib/apt/lists/*

# Create a non-root user with passwordless sudo — mirrors the 'vscode' user
# in GitHub Codespaces devcontainer base images
RUN useradd -m -s /bin/bash dev && \
    echo "dev ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/dev

USER dev
WORKDIR /home/dev/dotfiles
