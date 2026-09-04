set -l fish_dir (path dirname (path resolve (status filename)))
set -l dotfiles_dir (path dirname $fish_dir)

set -l conf_dir $fish_dir/conf.d

if test -d $conf_dir
    for file in $conf_dir/*.fish
        source $file
    end
end

set -l local_conf $dotfiles_dir/local.fish
if test -f $local_conf
    source $local_conf
end
