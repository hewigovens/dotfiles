if test (uname) = Darwin
    alias op='open'
    alias x2b='plutil -convert binary1'
    alias b2x='plutil -convert xml1'
    alias pplist='/usr/libexec/PlistBuddy -c "Print"'
    alias plistbuddy='/usr/libexec/PlistBuddy'
    alias plisteditor='open -b com.apple.PropertyListEditor'
    alias sha1='shasum'
    alias sha256='shasum -a 256'
    alias claude="~/.claude/local/claude"
end
