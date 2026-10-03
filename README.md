# Dotfiles

Personal shell, editor, terminal, and keyboard configuration.

## Dependencies

```sh
brew bundle install
```

## Layout

```text
fish/                   Fish configuration and plugin list
  conf.d/               Environment, aliases, and functions
kbd/                    Keyboard layouts and Karabiner configuration
shader/                 Terminal shaders
squirrel/               Squirrel input method configuration
z/                      Zellij configuration and layouts
Brewfile                Homebrew dependencies
install.sh              Configuration symlink installer
```

Git, Jujutsu, Vim, tmux, Ghostty, and Claude settings live at the repository root.

## Fish

`fish/config.fish` loads `fish/conf.d/*.fish` in order, then the optional,
untracked `local.fish` at the repository root for machine-specific settings.
