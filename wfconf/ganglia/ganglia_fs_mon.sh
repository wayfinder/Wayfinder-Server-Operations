#!/bin/sh

gmetric_args="--tmax=240 --dmax=240 --units=kB --type=uint32"

egrep "ext2|ext3|reiserfs|xfs" /proc/mounts | while read fs_raw
do
	fs=`echo $fs_raw | awk -F ' ' '{print $2}'`
	df=`df $fs | grep -v Filesystem`
        df=`echo $df | tr -d '\n'`
	size=`echo $df | awk -F ' ' '{print $2}'`
	free=`echo $df | awk -F ' ' '{print $4}'`
	if [ "$fs" = "/" ]
	then
		fs_name="root"
        else
		fs_name=`echo $fs | sed -e 's#^/##' -e 's#/#_#g'`
	fi
	gmetric $gmetric_args --name=fs_size_${fs_name} --value=$size
	gmetric $gmetric_args --name=fs_free_${fs_name} --value=$free
done
