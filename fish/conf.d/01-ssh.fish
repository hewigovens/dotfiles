if status is-interactive && set -q SSH_TTY
    if test (uname) = Darwin
        # Use macOS Keychain for SSH keys - agent is managed by launchd
        set -gx SSH_ASKPASS /usr/bin/ssh-askpass
    end
end
