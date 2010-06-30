#!/bin/sh

if [ "$1" == "" ]; then
   echo "No directory specified. Example usage:"
   echo "$0 keys.xxx/n1"
   exit
fi

mkdir -vp $1
ssh-keygen -t rsa1 -f $1/ssh_host_key -C '' -N ''
ssh-keygen -t rsa -f $1/ssh_host_rsa_key -C '' -N ''
ssh-keygen -t dsa -f $1/ssh_host_dsa_key -C '' -N ''

