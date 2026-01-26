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
