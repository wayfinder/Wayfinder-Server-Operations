#!/bin/bash

. /mc2/etc/cluster.conf

if [[ "`basename $0`" = "conf.sh" ]]; then
	rm -f mc2control-*
	./your-mc2conf.pl
        echo
fi

echo -n "Sync to "
for node in ${MC2NODES[*]} ; do
   echo -n "${node} ... "
   eval ${RS} $* -q /mc2/etc/ mc2@${node}:/mc2/etc/
done
echo "Done!"
