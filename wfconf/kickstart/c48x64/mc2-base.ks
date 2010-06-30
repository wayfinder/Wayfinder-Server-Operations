
# Install (eg not upgrade)
install

# The installation files
nfs --server=kickstart --dir=/kick/dist/src/centos-4.8-x86_64/iso

# Language support setup
lang en_US.UTF-8
langsupport --default=en_US.UTF-8 en_US.UTF-8 en_US

# System keyboard
keyboard sv-latin1

# System mouse
mouse generic3ps/2

# Network interface, use DHCP
network --bootproto dhcp

# root password
<ROOTPW>

# disable default firewall
firewall --disabled

# turn on SELinux
selinux --enforcing

# use shadow MD5 passwords
authconfig --enableshadow --enablemd5

# System timezone
timezone Europe/Copenhagen

# put GRUB in MBR
bootloader --location=mbr

#Reboot after installation
reboot

#Use text mode install
text

# dont use X at all
skipx

# partitions and file systems

<PARTITIONING>

%packages --resolvedeps
# minimal install, everything else handled using WFConf and yum
# zsh since we have shell scripts using it (eg WFConf)
zsh
# we definitely don't want these:
-cyrus-sasl-sql.i386
-mysql.i386
-mysqlclient10.i386

%post
(
# remove serial console support in grub, it's handled by the redirect
# in the BIOS instead since the default grub handling causes a hang
# instead of a continued boot on at least the Dell SC1425s.
perl -pi -e 's/^serial/#serial/g' /boot/grub/grub.conf
perl -pi -e 's/^terminal/#terminal/g' /boot/grub/grub.conf

<GRUBFIX>

# Mount /kick so we can access the config files
mkdir /tmp/kick
echo "* Mounting kickstart:/kick"
mount kickstart:/kick /tmp/kick
echo "* Setting up the network and hostname"
# fix hostname
sed -i -e 's/int-//g' /etc/sysconfig/network
source /etc/sysconfig/network
echo "* Fix yum/rpm"
cp -v /tmp/kick/wfconf/yum/Wayfinder-CentOS.repo /etc/yum.repos.d/Wayfinder-CentOS.repo
cp -v /tmp/kick/wfconf/yum/Wayfinder-EL4.repo /etc/yum.repos.d/Wayfinder-EL4.repo
cp -v /tmp/kick/wfconf/yum/Wayfinder-3rd.repo /etc/yum.repos.d/Wayfinder-3rd.repo
rm /etc/yum.repos.d/CentOS-Base.repo
rpm --import /usr/share/doc/centos-release-4/RPM-GPG-KEY-centos4
rpm --import /tmp/kick/wfconf/rpm/RPM-GPG-KEY-wayfinder
echo "* Installing CentOS plus kernel"
echo "  - Removing old normal kernel"
rpm -e kernel
echo "  - Updating kernel-smp with centosplus kernel"
rpm -Uv /tmp/kick/dist/src/centos-4.8-x86_64/centosplus/kernel-smp-2.6.9-89.0.23.plus.c4.x86_64.rpm
rpm -Uv /tmp/kick/dist/src/centos-4.8-x86_64/centosplus/kmod-xfs-smp-0.4-2.el4.x86_64.rpm
echo "* Installing additional critical packages"
echo "  - Installing ReiserFS tools"
rpm -Uv /tmp/kick/dist/src/centos-4.8-x86_64/centosplus/reiserfs-utils-3.6.19-2.4.1.x86_64.rpm
echo "  - Installing XFS tools"
rpm -Uv /tmp/kick/dist/src/centos-4.8-x86_64/centosplus/xfsprogs-2.9.4-1.el4.centos.x86_64.rpm
echo "* wfconf config provisioning"
echo " - Copying current wfconf tree to /tmp"
cp -a /tmp/kick/wfconf /tmp
echo " - Add service file and enable it"
install --verbose -C --mode 755 --preserve-timestamps --owner root --group root /tmp/kick/wfconf/wfconf_hg.init /etc/init.d/wfconf
chkconfig --add wfconf
echo "* Unmounting kickstart:/kick"
umount /tmp/kick
rmdir /tmp/kick
) 2>&1 | tee /root/kick-post.log > /dev/console
