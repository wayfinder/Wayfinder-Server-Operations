zerombr yes
clearpart --initlabel
partition /boot           --fstype=ext3 --ondisk=sda --size=256        --asprimary
partition pv.01                       --ondisk=sda --size=100        --asprimary --grow 
volgroup sysvg pv.01 --pesize=32768
logvol /     --fstype ext3     --name=root --vgname=sysvg --size=512
logvol /var  --fstype ext3     --name=var  --vgname=sysvg --size=2000
logvol /usr  --fstype ext3     --name=usr  --vgname=sysvg --size=4000
logvol /tmp  --fstype ext3     --name=tmp  --vgname=sysvg --size=1024
logvol swap  --fstype swap     --name=swap --vgname=sysvg --size=4096

