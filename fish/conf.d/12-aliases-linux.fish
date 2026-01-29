if test (uname) = Linux
    alias sha1='sha1sum'
    alias sha256='sha256sum'

    function say
        echo "$argv" | espeak -s 240 2>/dev/null
    end
end
