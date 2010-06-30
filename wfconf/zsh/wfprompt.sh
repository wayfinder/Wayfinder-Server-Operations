if [ "$SHELL" = "/bin/bash" ]; then
   export PS1="[\u@\H]\w\$ "
fi

if [ "$SHELL" = "/bin/zsh" ]; then
   export PS1="[%n@%M]%~%# "
fi

