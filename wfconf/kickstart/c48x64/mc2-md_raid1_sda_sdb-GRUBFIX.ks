
# START Fix grub booting for software raid
/sbin/grub 2>&1 >/root/grub-fixup.log << EOF
root (hd0,1)
setup (hd0)
device (hd0) /dev/sdb
root (hd0,1)
setup (hd0)
EOF
