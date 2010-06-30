# intended for cluster manegement nodes
zerombr yes
clearpart --all --initlabel
partition raid.01 --size=128 --ondisk=sda --asprimary
partition raid.02 --size=128 --ondisk=sdb --asprimary
partition raid.03 --size=100 --grow --ondisk=sda
partition raid.04 --size=100 --grow --ondisk=sdb
raid /boot --level=1 --device=md0 raid.01 raid.02
raid pv.01 --level=1 --device=md1 raid.03 raid.04
volgroup sysvg pv.01 --pesize=32768
logvol /     --fstype=ext3     --name=root --vgname=sysvg --size=512
logvol /var  --fstype=ext3     --name=var  --vgname=sysvg --size=2000
logvol /usr  --fstype=ext3     --name=usr  --vgname=sysvg --size=4000
logvol /tmp  --fstype=ext3     --name=tmp  --vgname=sysvg --size=1024
logvol swap  --fstype=swap     --name=swap --vgname=sysvg --size=4096
