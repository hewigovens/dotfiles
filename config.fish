if status is-interactive && string length -q -- $SSH_TTY
    if test (uname) = Darwin
        eval (ssh-agent -c)
        ssh-add -k --apple-use-keychain
    end
end

set fish_greeting
set -x HOMEBREW_NO_ENV_HINTS 1
set -gx ANDROID_HOME $HOME/Library/Android/sdk

# Nav
alias ...='cd .. && cd ..'
alias l='ls -alh'
alias ll='ls -alh@'
alias la='ls -a'

# Utils
alias psgrep='ps -ef | grep -v grep | grep -ni'
alias g='grep -ni' # Case insensitive grep
alias f='find . | grep -ni'
alias ducks='du -cksh * | sort -rn|head -11' # Lists folders and files sizes in the current folder
alias duck='du -h -d1'
alias df='df -h'
alias profileme="history | awk '{print \$2}' | awk 'BEGIN{FS=\"|\"}{print \$1}' | sort | uniq -c | sort -n | tail -n 20 | sort -nr"
alias cls='clear'

# Git
alias gs='git status'
alias ga='git add'
alias gcl='git clone'
alias gco='git checkout'
alias gl='git log -p --color --stat --graph'
alias glf='git log -p --color --stat --graph --follow'
alias gdf='git diff --color --ignore-space-at-eol'
alias gft='git difftool'
alias gmt='git mergetool'
alias grc='git rebase --continue'
alias gra='git rebase --abort'
alias gpl='git pull'
alias gp='git push'
alias gbd='git branch -D'

# tmux
alias tn='tmux new-session -s'
alias tl='tmux list-session'
alias ta='tmux attach -t'
alias td='tmux detach'

function int2hex
    math --base=hex $argv
end

function hex2int
    math $argv
end

function local_ip
    ifconfig | grep broadcast | awk '{print $2}'
end

if test (uname) = Darwin
    # CocoaPods
    alias pdi="pod install --verbose"
    alias pdu="pod install --verbose --repo-update"
    alias pd="pod install"

    # macOS
    alias op='open'
    alias x2b='plutil -convert binary1'
    alias b2x='plutil -convert xml1'
    alias pplist='/usr/libexec/PlistBuddy -c "Print"'
    alias plistbuddy='/usr/libexec/PlistBuddy'
    alias plisteditor='open -b com.apple.PropertyListEditor'
    alias listallkext='kextstat -l'
    alias listkext='kextstat -l | grep -v apple'
    alias sha1='shasum'
    alias sha256='shasum -a 256'
    alias gitup='gitup commit'

    function restart_finder
        echo 'tell application "Finder" to quit' | osascript
        open -a Finder
    end

    function show_desktop_icons
        defaults write com.apple.finder CreateDesktop -bool true
        restart_finder
    end

    function hide_desktop_icons
        defaults write com.apple.finder CreateDesktop -bool false
        restart_finder
    end

    function dequarantine
        xattr -d com.apple.quarantine "$argv"
    end

    if test -f ~/.config/fish/iterm2.fish
        source ~/.config/fish/iterm2.fish
    end
end
