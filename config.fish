if status is-interactive && string length -q -- $SSH_TTY
    if test (uname) = Darwin
        eval (ssh-agent -c)
        ssh-add -k --apple-use-keychain
    end
end

set fish_greeting
set -x HOMEBREW_NO_ENV_HINTS 1
set -gx ANDROID_HOME $HOME/Library/Android/sdk

# Function to load grouped aliases
function load_aliases
    # Navigation aliases
    function load_nav_aliases
        alias ...='cd .. && cd ..'
        alias l='ls -alh'
        alias ll='ls -alh@'
        alias la='ls -a'
    end

    # Utility aliases
    function load_util_aliases
        alias psgrep='ps -ef | grep -v grep | grep -ni'
        alias g='grep -ni' # Case insensitive grep
        alias f='find . | grep -ni'
        alias ducks='du -cksh * | sort -rn|head -11' # Lists folders and files sizes in the current folder
        alias duck='du -h -d1'
        alias df='df -h'
        alias profileme="history | awk '{print \$2}' | awk 'BEGIN{FS=\"|\"}{print \$1}' | sort | uniq -c | sort -n | tail -n 20 | sort -nr"
        alias cls='clear'
    end

    # Git aliases
    function load_git_aliases
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
    end

    # macOS specific aliases
    function load_macos_aliases
        if test (uname) = Darwin
            alias op='open'
            alias x2b='plutil -convert binary1'
            alias b2x='plutil -convert xml1'
            alias pplist='/usr/libexec/PlistBuddy -c "Print"'
            alias plistbuddy='/usr/libexec/PlistBuddy'
            alias plisteditor='open -b com.apple.PropertyListEditor'
            alias sha1='shasum'
            alias sha256='shasum -a 256'
        end
    end

    # Load all alias groups
    load_nav_aliases
    load_util_aliases
    load_git_aliases
    load_macos_aliases
end

# Utility functions
function int_to_hex
    math --base=hex $argv
end

function str_to_hex
    echo -n $argv | xxd -p
end

function hex_to_int
    math $argv
end

function hex_to_str
    echo $argv | xxd -p -r
end

function local_ip
    ifconfig | grep broadcast | awk '{print $2}'
end

function reverse_hex
    set str $argv[1]

    # Remove '0x' prefix if present
    if string match -q "0x*" $str
        set str (string sub -s 3 $str)
    end

    # Add leading zero if length is odd
    set len (string length $str)
    set remainder (math "$len % 2")
    if test $remainder -ne 0
        set str "0$str"
    end

    # Split the hex string into pairs of characters
    set pairs
    for i in (seq 1 2 (string length $str))
        set -a pairs (string sub -s $i -l 2 $str)
    end

    # Reverse the pairs and join them
    set reversed_pairs $pairs[-1..1]
    set reversed (string join "" $reversed_pairs)

    echo $reversed
end

# macOS specific functions
if test (uname) = Darwin
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
end

# Function to load NVM
function load_nvm
    if test -d "$HOME/.nvm"
        nvm use latest
    end
end

# Load all aliases and NVM
load_aliases
load_nvm
