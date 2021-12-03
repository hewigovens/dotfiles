if status is-interactive
    # Commands to run in interactive sessions can go here
end

set fish_greeting

# Nav
alias ...='cd .. && cd ..'
alias l='ls -alh'
alias ll='ls -alh@'
alias la='ls -a'

# Utils
alias psgrep='ps -ef | grep -v grep | grep -ni'
alias g='grep -ni'  # Case insensitive grep
alias f='find . | grep -ni' 
alias ducks='du -cksh * | sort -rn|head -11' # Lists folders and files sizes in the current folder
alias duck='du -h -d1' 
alias df='df -h'
alias profileme="history | awk '{print \$2}' | awk 'BEGIN{FS=\"|\"}{print \$1}' | sort | uniq -c | sort -n | tail -n 20 | sort -nr"
alias cls='clear'

# Git
alias gs='git status'
alias gcl='git clone'
alias gco='git checkout'
alias gl='git log -p --color --stat --graph'
alias glf='git log -p --color --stat --graph --follow'
alias gf='git diff --color --ignore-space-at-eol'
alias gft='git difftool'
alias gmt='git mergetool'
alias grc='git rebase --continue'
alias gra='git rebase --abort'

# pod
alias pdi="pod install --verbose"
alias pdu="pod install --verbose --repo-update"
alias pd="pod install"

# tmux
alias tn='tmux new-session -s'
alias tl='tmux list-session'
alias ta='tmux attach -t'
alias td='tmux detach'

alias dla='youtube-dl --ignore-errors --output "%(title)s.%(ext)s" --extract-audio --audio-format m4a'

# wc
alias wc_cmake="cmake -H. -Bbuild -DCMAKE_BUILD_TYPE=Debug"
alias wc_make="make -Cbuild -j12 tests && build/tests/tests tests"

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

export HOMEBREW_NO_ENV_HINTS=1
