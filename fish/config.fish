set -l conf_dir ~/dotfiles/fish/conf.d

if test -d $conf_dir
    for file in $conf_dir/*.fish
        source $file
    end
end

set -l local_conf ~/dotfiles/local.fish
if test -f $local_conf
    source $local_conf
end
