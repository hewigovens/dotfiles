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
agents/                 Optional local instructions for coding agents (untracked)
Brewfile                Homebrew dependencies
install.sh              Configuration symlink installer
```

Git, Jujutsu, Vim, tmux, Ghostty, and Claude settings live at the repository root.

## Fish

`fish/config.fish` loads `fish/conf.d/*.fish` in order, then the optional,
untracked `local.fish` at the repository root for machine-specific settings.

Run `bash install.sh` to link the configuration, install Fisher if needed, and
install or update the plugins listed in `fish/fish_plugins`. This step requires
Fish, curl, and network access; if Fish is missing, install it and re-run the
installer. Later, run `fisher update` from Fish to sync the plugin list.

## Shared agent instructions

Create or edit the optional, gitignored `agents/AGENTS.md` to set personal
engineering defaults across projects. When the file exists, `install.sh` links
it to both global entry points; otherwise, it leaves those entry points unchanged:

| Tool | Global instruction file |
| --- | --- |
| Codex | `~/.codex/AGENTS.md`, or `$CODEX_HOME/AGENTS.md` when set |
| Claude Code | `~/.claude/CLAUDE.md` |

Start a fresh session after changing the guide. Project-specific instructions
stay in each project's `AGENTS.md` or `CLAUDE.md`; the shared stack preferences
are defaults for new work, not a request to migrate existing projects.

These links apply on machines where the dotfiles are installed. Remote or hosted
sessions need their own copy of the instructions. Keep the global guide short;
store detailed project knowledge and task-specific procedures with their owners.

See the official [Codex instruction guide](https://learn.chatgpt.com/docs/agent-configuration/agents-md)
and [Claude Code memory guide](https://code.claude.com/docs/en/memory).
