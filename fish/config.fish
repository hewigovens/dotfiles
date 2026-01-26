set -l conf_dir ~/dotfiles/fish/conf.d

if test -d $conf_dir
    for file in $conf_dir/*.fish
        source $file
    end
end
