unsetopt correct
setopt autocd
setopt automenu
setopt autoparamslash
setopt autoremoveslash
setopt cdablevars
setopt histignoredups
setopt histverify
setopt nohup
setopt listtypes
setopt longlistjobs
setopt pathdirs
setopt nobeep

bindkey -e
bindkey "^[[A" up-line-or-search
bindkey "^[[B" down-line-or-search

export LESS="-mI"

alias vi=vim
export PS1="%m:%S%n%s:%3c$ "

iren ()
{
        while [ "$1" != "" ]
        do
                source=$1
                dest=$1
                vared dest
                if [ "$source" != "$dest" ]
                then
                        mv "$source" "$dest"
                fi
                shift
        done
}

alias rs="rsync --verbose --recursive --links --perms --owner --group --times --one-file-system --delete --stats --progress --rsh=ssh"
alias rscopylinks="rsync --verbose --recursive --links --copy-unsafe-links --perms --owner --group --times --one-file-system --delete --stats --progress --rsh=ssh"

utime ()
{
     perl -e "print localtime($1) . \"\n\""
}

mvmtime ()
{
   perl -e 'use File::stat; use POSIX qw(strftime); $file = shift; $sb = stat($file); $mtstr = strftime "%Y%m%d", localtime($sb->mtime); $nfile = $
file; $nfile =~ s/\.([^.]*)$/.$mtstr.\1/g; system("mv $file $nfile");' $*
}

nextnode ()
{
    thisnode=`hostname -s | sed -e 's/.*n//'`
    echo n$[$thisnode + 1]
}
