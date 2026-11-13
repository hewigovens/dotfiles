#!/bin/bash
set -e

DOTFILES=~/dotfiles

link() {
    local src="$1"
    local dst="$2"

    if [ -L "$dst" ]; then
        local current
        current=$(readlink "$dst")
        if [ "$current" = "$src" ]; then
            return
        fi
        echo "Removing symlink: $dst"
        rm "$dst"
    elif [ -e "$dst" ]; then
        echo "Backing up: $dst -> $dst.bak"
        mv "$dst" "$dst.bak"
    fi

    mkdir -p "$(dirname "$dst")"
    ln -s "$src" "$dst"
    echo "Linked: $dst -> $src"
}

# Git
link "$DOTFILES/.gitconfig" ~/.gitconfig
link "$DOTFILES/.gitignore" ~/.gitignore
link "$DOTFILES/.gitattributes" ~/.gitattributes
link "$DOTFILES/jj.config.toml" ~/.config/jj/config.toml

# Commit signing: only when the key exists, so git and jj still work without it
SIGNING_KEY=~/.ssh/sign_ed25519
if [ -f "$SIGNING_KEY" ]; then
    link "$DOTFILES/.gitconfig.signing" ~/.gitconfig.signing
    link "$DOTFILES/jj.signing.toml" ~/.config/jj/conf.d/signing.toml
else
    echo "Skipping commit signing: $SIGNING_KEY not found (re-run after adding it)"
fi

# Vim
link "$DOTFILES/.vimrc" ~/.vimrc

# Fish
link "$DOTFILES/fish/config.fish" ~/.config/fish/config.fish
link "$DOTFILES/fish/fish_plugins" ~/.config/fish/fish_plugins

if command -v fish >/dev/null 2>&1; then
    if ! fish -c 'functions -q fisher'; then
        echo "Installing Fisher and Fish plugins..."
        fisher_bootstrap=$(mktemp)
        trap 'rm -f "$fisher_bootstrap"' EXIT
        curl -fsSL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish -o "$fisher_bootstrap"
        fish -c 'source "$argv[1]"; or exit 1; fisher update' "$fisher_bootstrap"
        rm -f "$fisher_bootstrap"
        trap - EXIT
    else
        echo "Updating Fish plugins..."
        fish -c 'fisher update'
    fi
else
    echo "Skipping Fisher: fish not found (install Fish and re-run)"
fi

# Zellij
link "$DOTFILES/z/config.kdl" ~/.config/zellij/config.kdl

# Agents
link "$DOTFILES/claude.settings.json" ~/.claude/settings.json
if [ -f "$DOTFILES/agents/AGENTS.md" ]; then
    link "$DOTFILES/agents/AGENTS.md" "${CODEX_HOME:-$HOME/.codex}/AGENTS.md"
    link "$DOTFILES/agents/AGENTS.md" ~/.claude/CLAUDE.md
fi

echo "Done!"
