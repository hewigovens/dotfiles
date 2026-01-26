# Navigation
alias ...='cd .. && cd ..'
alias l='ls -alh'
alias ll='ls -alh@'
alias la='ls -a'

# Utilities
alias psgrep='ps -ef | grep -v grep | grep -ni'
alias g='grep -ni'
alias f='find . | grep -ni'
alias ducks='du -cksh * | sort -rn|head -11'
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
alias gf='git diff -p --color'
alias gdf='git diff --color --ignore-space-at-eol'
alias gft='git difftool'
alias gmt='git mergetool'
alias grc='git rebase --continue'
alias gra='git rebase --abort'
alias gpl='git pull'
alias gp='git push'
alias gbd='git branch -D'

# Tools
alias z='zellij'
