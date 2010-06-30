# 'less' settings
export LESS="-eMi"

# Various usable aliases
alias 'l=ls -F'
alias 'll=ls -lF'
alias 'la=ls -lFa'

# Add some usable paths for all users.
wf_pathmunge () {
   if ! echo $PATH | /bin/egrep -q "(^|:)$1($|:)" ; then
      if [ "$2" = "after" ] ; then
         PATH=$PATH:$1
      else
         PATH=$1:$PATH
            fi
            fi
}
wf_pathmunge /sbin
wf_pathmunge /usr/sbin
wf_pathmunge /usr/local/sbin
unset wf_pathmunge
