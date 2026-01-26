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
            echo "Already linked: $dst"
            return
        fi
        echo "Removing existing symlink: $dst"
        rm "$dst"
    elif [ -e "$dst" ]; then
        echo "Backing up: $dst -> $dst.bak"
        mv "$dst" "$dst.bak"
    fi

    mkdir -p "$(dirname "$dst")"
    ln -s "$src" "$dst"
    echo "Linked: $dst -> $src"
}

echo "Installing dotfiles..."

# Git
link "$DOTFILES/.gitconfig" ~/.gitconfig
link "$DOTFILES/.gitignore" ~/.gitignore
link "$DOTFILES/.gitattributes" ~/.gitattributes

# Vim
link "$DOTFILES/.vimrc" ~/.vimrc

# Fish
link "$DOTFILES/fish/config.fish" ~/.config/fish/config.fish
link "$DOTFILES/fish/fish_plugins" ~/.config/fish/fish_plugins

# Zellij
link "$DOTFILES/z/config.kdl" ~/.config/zellij/config.kdl

echo "Done!"
