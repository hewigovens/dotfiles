function google
    gemini -p "Search google for <query>$argv</query> and summarize results"
end

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

function update_node_alias
    sudo ln -sf ~/.local/share/fnm/aliases/default/bin/node /usr/local/bin/node
    sudo ln -sf ~/.local/share/fnm/aliases/default/bin/npm /usr/local/bin/npm
    sudo ln -sf ~/.local/share/fnm/aliases/default/bin/npx /usr/local/bin/npx
    sudo ln -sf ~/.local/share/fnm/aliases/default/bin/corepack /usr/local/bin/corepack

    echo "Node.js symlinks updated"
    echo "node: $(node --version)"
    echo "npm: $(npm --version)"
    echo "npx: $(npx --version)"
    echo "corepack: $(corepack --version)"
end


function __fish_user_path_remove_at -a index
    set -l path $fish_user_paths[$index]
    set -e fish_user_paths[$index]
    echo "Removed [$index]: $path"
end

function fish_list_paths
    set -l count (count $fish_user_paths)
    if test $count -gt 0
        for i in (seq $count)
            printf "%d: %s\n" $i $fish_user_paths[$i]
        end
    end
end

function fish_remove_path_idx -a index
    if test -z "$index"; or not string match -q -r '^\d+$' "$index"
        echo "Usage: fish_remove_path_idx <index>"
        return 1
    end

    set -l count (count $fish_user_paths)
    if test "$index" -ge 1 -a "$index" -le "$count"
        __fish_user_path_remove_at "$index"
    else
        echo "Error: index $index out of range (1-$count)"
        return 1
    end
end

function fish_remove_path -a path
    if test -z "$path"
        echo "Usage: fish_remove_path <full_path>"
        return 1
    end

    if set -l index (contains -i "$path" $fish_user_paths)
        __fish_user_path_remove_at "$index"
    else
        echo "Error: path '$path' not found in \$fish_user_paths"
        return 1
    end
end
