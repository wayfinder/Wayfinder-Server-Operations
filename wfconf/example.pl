#!/usr/bin/perl -w
#
# This is an example WFConf file. It has not been tested at all and is based on
# a live config with lots of things removed/renamed. An important item that was
# removed is network and firewall configurations. Those you will have to supply
# yourself.
#
# Copyright (c) 1999 - 2010, Vodafone Group Services Ltd
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# 
#     * Redistributions of source code must retain the above copyright notice,
#     this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright
#     notice, this list of conditions and the following disclaimer in the
#     documentation and/or other materials provided with the distribution.
#     * Neither the name of the Vodafone Group Services Ltd nor the names of
#     its contributors may be used to endorse or promote products derived from
#     this software without specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

use FindBin;
use lib $FindBin::Bin;
use WFConf;
use strict;

# config definitions
# ------------------

# pre-defined variables that can be used:
# $host      - Value returned by hostname -s
# $full_host - Value returned by hostname
# $cluster   - Domain part of host name, adjusted for old sins
#

debug_print(1, "DEBUG [wfconf] host: $host\n");

# The config files should be here...
$config_file_dir = $FindBin::Bin;

$config{'generic_server'} = <<EOF
# mysql and mc2 users added here to make sure it's always available - both for MySQL and for fs/file rights
group('mysql', 101);
user('mysql', 101, '/var/lib/mysql', '/bin/zsh', 'mysql', undef);
group('mc2', 500);
user('mc2', 500, '/mc2', '/bin/zsh', 'mc2', undef);
file_system('sysvg/wayf',  '/wayf',            '128M',  'mc2.mc2',     '1755', 'ext3',     '150000');
packages('bind-9.2.4-30.el4_7.2','bind-chroot','ntp','OpenIPMI-tools', 'vim-enhanced', 'strace', 'sysstat',
         'kernel-smp-2.6.9-89.0.23.plus.c4', 'kmod-xfs-smp-0.4-2.el4.x86_64.rpm',
         'ipsec-tools-0.6.6',
	 'openssh-3.9p1-11.el4_7',
         'ganglia-gmond',
         'glibc-wfcommon',
         'sendmail-cf',
         'gd-2.0.33-9.3.el4.wayf.1', 'gd-2.0.33-9.3.el4.wayf.1.i386',
         'mercurial-1.1-1.el4.wayf');
dir('/etc/wayf', '755', 'root.root');
# SSH host keys
dir('/root/.ssh', '700', 'root.root');
file('ssh/keys.$cluster/$host/ssh_host_key',         '/etc/ssh/ssh_host_key',         '600', 'root.root');
file('ssh/keys.$cluster/$host/ssh_host_dsa_key',     '/etc/ssh/ssh_host_dsa_key',     '600', 'root.root');
file('ssh/keys.$cluster/$host/ssh_host_rsa_key',     '/etc/ssh/ssh_host_rsa_key',     '600', 'root.root');
file('ssh/keys.$cluster/$host/ssh_host_key.pub',     '/etc/ssh/ssh_host_key.pub',     '644', 'root.root');
file('ssh/keys.$cluster/$host/ssh_host_dsa_key.pub', '/etc/ssh/ssh_host_dsa_key.pub', '644', 'root.root');
file('ssh/keys.$cluster/$host/ssh_host_rsa_key.pub', '/etc/ssh/ssh_host_rsa_key.pub', '640', 'root.root');
file('ssh/keys.$cluster/root/authorized_keys',       '/root/.ssh/authorized_keys',    '644', 'root.root');
file('ssh/keys.$cluster/root/id_dsa',                '/root/.ssh/id_dsa',             '600', 'root.root');
file('ssh/keys.$cluster/root/id_dsa.pub',            '/root/.ssh/id_dsa.pub',         '644', 'root.root');
file('ssh/known_hosts.$cluster',                     '/root/.ssh/known_hosts',        '644', 'root.root');
file('ssh/sshd_config',                              '/etc/ssh/sshd_config',          '644', 'root.root');
# wf-eu init file
file('wfconf_hg.init',                               '/etc/init.d/wfconf',             '755', 'root.root');
# Updatedb configuration file
file('updatedb/updatedb.conf', '/etc/updatedb.conf',     '644', 'root.root');
# Network stuff
file('network/hosts.$cluster',          '/etc/hosts',             '644', 'root.root');
file('network/resolv.conf.$cluster',    '/etc/resolv.conf',       '644', 'root.root');
# Yum repos
file('yum/Wayfinder-CentOS.repo', '/etc/yum.repos.d/Wayfinder-CentOS.repo', '644', 'root.root');
file('yum/Wayfinder-EL4.repo',    '/etc/yum.repos.d/Wayfinder-EL4.repo',    '644', 'root.root');
# NTP
file('ntp/ntp.conf',     '/etc/ntp.conf',             '644', 'root.root');
file('ntp/step-tickers', '/etc/ntp/step-tickers',     '644', 'root.root');
# unpackaged tools
file('bin/wftee.$arch',                 '/usr/local/bin/wftee',                            '755', 'root.root');
# sysctl
file('misc/sysctl.conf',     '/etc/sysctl.conf',             '644', 'root.root');
# logrotate
file('logrotate/logrotate.conf', '/etc/logrotate.conf',      '644', 'root.root');
# mail / sendmail
file('mail/aliases',         '/etc/aliases',                 '644', 'root.root');
file('mail/sendmail.mc.$cluster', '/etc/mail/sendmail.mc', '644', 'root.root');
# rpm settings
file('rpm/macros.wayf',      '/etc/rpm/macros.wayf',         '644', 'root.root');
# ganglia
file('ganglia/gmond.conf.$cluster',          '/etc/gmond.conf',                  '644', 'root.root');
file('ganglia/cron.ganglia_fs_mon', '/etc/cron.d/ganglia_fs_mon',       '644', 'root.root');
file('ganglia/ganglia_fs_mon.sh',   '/usr/local/bin/ganglia_fs_mon.sh', '755', 'root.root');
perms('/usr/bin/gmetric', '511', 'root.root');
service('gmond', 'on', 'restart');
# prompt
file('zsh/wfprompt.sh',		'/etc/profile.d/wfprompt.sh',		'755',	'root.root');
file('zsh/zlogin',			'/etc/zlogin',						'755',	'root.root');
# turn on named
service('named', 'on', 'restart');
# Turn off the annoying kudzu service
service('kudzu', 'off', 'stop');
# Turn on loading of the IPMI local device driver
service('ipmi', 'on', 'start');
# Make sure that ssh is on and restart it to catch any changes
service('sshd', 'on', 'restart');
# Make sure that ntpd is on and restart it to sync the time
service('ntpd', 'on', 'restart');
service('sendmail', 'on', 'restart');
# CentOS default yum repo defs are stupidly enough inside the centos-release RPM
nofile('/etc/yum.repos.d/CentOS-Base.repo');
nofile('/etc/yum.repos.d/CentOS-Media.repo');
# generate new aliases
shell('newaliases');
EOF
;

$config{'mc2_server_common'} = <<EOF
dir('/mc2/.ssh', '700', 'mc2.mc2');
file('ssh/keys.$cluster/mc2/authorized_keys',       '/mc2/.ssh/authorized_keys',          '644', 'mc2.mc2');
file('ssh/keys.$cluster/mc2/id_dsa',                '/mc2/.ssh/id_dsa',                   '600', 'mc2.mc2');
file('ssh/keys.$cluster/mc2/id_dsa.pub',            '/mc2/.ssh/id_dsa.pub',               '644', 'mc2.mc2');
file('ssh/known_hosts.$cluster',                    '/mc2/.ssh/known_hosts',              '644', 'mc2.mc2');
file('zsh/mc2.zshrc',                               '/mc2/.zshrc',                        '644', 'mc2.mc2');
file('cron/compress_mc2_logs.cron',                 '/etc/cron.d/compress_mc2_logs.cron', '644', 'root.root');
# multicast route for MC2
file('network/static-routes.$cluster',              '/etc/sysconfig/static-routes',       '644', 'root.root');
packages('gd.i386', 'ImageMagick.i386', 'ImageMagick.x86_64', 'ImageMagick5-5.4.3.11-1.el4.wayf.4.x86_64',
         'JTC-2.0.0', 'XercesC-2.6.0', 'postgresql-libs.x86_64',
         'EasySoap++-0.6.1','libtecla-1.4.1', 'cairo-1.4.6', 'libmemcached',
         'screen', 'squid', 'librsvg2',
	 'caching-nameserver',
         'perl-XML-LibXML', 'perl-XML-XPath', 'perl-WWW-Curl', 'perl-SOAP-Lite', 'perl-Digest-HMAC', 'perl-Crypt-SSLeay',
         'jre-1.5.0_09-fcs');
file_system('sysvg/mc2',   '/mc2',             '2G',    'mc2.mc2',     '1755', 'ext3',     '150000');
file_system('sysvg/logs',  '/logs',            '2G',    'mc2.mc2',     '1755', 'ext3',     '150000');
dir('/logs/old', '755', 'mc2.mc2');
EOF
;

$config{'mc2_server_be'} = <<EOF
file_system('sysvg/maps',  '/maps',            '120G',   'mc2.mc2',     '1755', 'ext3',     '150000');
file_system('sysvg/logs',  '/logs',            '2G',    'mc2.mc2',     '1755', 'ext3',     '150000');
dir('/logs/old', '755', 'mc2.mc2');
EOF
;

# squid only needed for XML FE's in practice, might want to split it out later
$config{'mc2_server_fe'} = <<EOF
# squid user added here to make sure it's always available
group('squid', 23);
user('squid', 23, '/var/spool/squid', '/sbin/nologin', 'squid', '-r');
file('squid/squid.conf',                           '/etc/squid/squid.conf',              '640', 'root.squid');
file('squid/squid',                                '/etc/init.d/squid',                  '755', 'root.root');
file_system('sysvg/tiles', '/tiles',           '6G',    'mc2.mc2',     '1755', 'reiserfs', '0');
file_system('sysvg/squid', '/var/spool/squid', '4G',    'squid.squid', '1755', 'reiserfs', '0');
file_system('sysvg/logs',  '/logs',            '10G',   'mc2.mc2',     '1755', 'ext3',     '150000');
# Make sure that squid is on and restart it to catch any changes
service('squid', 'on', 'restart');
EOF
;

$config{'db_client'} = <<EOF
packages('MySQL-client-community-5.0.85-0.rhel4', 'MySQL-shared-community-5.0.85-0.rhel4.i386', 
         'MySQL-shared-community-5.0.85-0.rhel4.x86_64', 
         'perl-DBD-MySQL');
EOF
;

$config{'dedicated_db_server'} = <<EOF
packages('MySQL-server-community', 
         'MySQL-client-community', 'MySQL-shared-community',
         'caching-nameserver',
);
file_system('sysvg/mysql', '/var/lib/mysql', '50G', 'mysql.mysql', '755', 'ext3', '20000');
file('mysql/my.cnf.$full_host', '/var/lib/mysql/my.cnf',        '644', 'root.root');
# MySQL needs more tmp space 
file_system('sysvg/tmp', '/tmp', '4G', 'root.root', '1777', 'ext3', '65536');
# mostly to fix security contexts
dir('/var/lib/mysql', '755', 'mysql.mysql');
service('mysql', 'on', 'start');
shell("/bin/true");
EOF
;

$config{'dedicated_web_server'} = <<EOF
packages('httpd-2.0.63', 'mod_ssl',
         'php-5.1.6-3.wayf.el4.1', 'php-gd-5.1.6-3.wayf.el4.1', 'php-mysql-5.1.6-3.wayf.el4.1',
         'php-eaccelerator-5.1.6_0.9.5', 'php-eaccelerator-web-5.1.6_0.9.5', 
         'php-soap-5.1.6-3.wayf.el4.1'
);
file_system('sysvg/www', '/var/www/sites', '50G', 'root.root', '755', 'ext3', '150000');
nofile('/etc/httpd/conf.d/welcome.conf');
nofile('/etc/php.d/soap.ini');
file('php/php.ini',                 '/etc/php.ini',                          '644', 'root.root');
file('apache/_vhost.conf',          '/etc/httpd/conf.d/_vhost.conf',      '644', 'root.root');
file('apache/mime.types',           '/etc/mime.types',                       '644', 'root.root');
# you would typically also add SSL config and certs here
#logrotate
file('logrotate/httpd', '/etc/logrotate.d/httpd', '644', 'root.root');
# Start apache if not already running
service('httpd', 'on', 'start');
# Reload apache if it was already running
service('httpd', 'on', 'reload');
shell("/bin/true");
EOF
;

# everything related to a management node in one single config, should probably 
# be split up for managability (and flexibility)
$config{'management_server'} = <<EOF
file_system('sysvg/archive', '/archive', '100G', 'root.root', '755', 'ext3', '500000');
file_system('sysvg/kick',    '/kick',    '25G',  'root.root', '755', 'ext3', '200000');
file_system('sysvg/www',     '/www',     '15G',  'root.root', '755', 'ext3', '800000');
file_system('sysvg/backup',  '/backup',  '60G',  'root.root', '755', 'ext3', '100000');
dir('/archive/logs', '755', 'mc2.mc2');
dir('/archive/dbbackup', '755', 'mc2.mc2');
dir('/kick/dist',    '755', 'root.root');
packages('tftp-server', 'bind', 'dhcp', 'mrepo', 'httpd', 'nagios', 'nagios-plugins',
);
# sys admin non-root accounts
group('admin', 501);
user('admin', 501, '/home/admin', '/bin/zsh', 'admin', undef);
dir('/home/ckk/.admin', '600', 'admin.admin');
file('ssh/keys.users/admin/authorized_keys',      '/home/admin/.ssh/authorized_keys',     '600', 'ckk.ckk');
group('admin2', 502);
user('admin2', 502, '/home/admin2', '/bin/zsh', 'admin2', undef);
dir('/home/admin2/.ssh', '600', 'admin2.admin2');
file('ssh/keys.users/admin2/authorized_keys',   '/home/admin2/.ssh/authorized_keys',  '600', 'admin2.admin2');
# dhcpd
file('dhcpd/dhcpd.conf.example',      '/etc/dhcpd.conf',               '644', 'root.root');
file('dhcpd/dhcpd.example',           '/etc/dhcpd.example',            '644', 'root.root');
# named
file('named/named.conf.example-mgmt', '/var/named/chroot/etc/named.conf',                     '644', 'root.root');
file('named/forward.localdomain',     '/var/named/chroot/var/named/data/forward.localdomain', '644', 'root.root');
file('named/forward.localhost',       '/var/named/chroot/var/named/data/forward.localhost',   '644', 'root.root');
file('named/forward.example',         '/var/named/chroot/var/named/data/forward.example',     '644', 'root.root');
file('named/named.ca',                '/var/named/chroot/var/named/data/named.ca',            '644', 'root.root');
file('named/reverse.10.210.1',        '/var/named/chroot/var/named/data/reverse.10.210.1',    '644', 'root.root');
file('named/reverse.127.0.0',         '/var/named/chroot/var/named/data/reverse.127.0.0',     '644', 'root.root');
service('named', 'on', "restart");
# kickstart, conf
file('kickstart/c48x64/mc2-base.ks',                                  '/kick/c47x64/ks/mc2-base.ks',                                  '644', 'root.root');
file('kickstart/c48x64/mc2-md_raid1_sda_sdb-GRUBFIX.ks',              '/kick/c47x64/ks/mc2-md_raid1_sda_sdb-GRUBFIX.ks',              '644', 'root.root');
file('kickstart/c48x64/mc2-nop-GRUBFIX.ks',                           '/kick/c47x64/ks/mc2-nop-GRUBFIX.ks',                           '644', 'root.root');
file('kickstart/c48x64/mc2-one_disk_sda-PARTITIONING.ks',             '/kick/c47x64/ks/mc2-one_disk_sda-PARTITIONING.ks',             '644', 'root.root');
file('kickstart/c48x64/mc2-md_raid1_sda_sdb-PARTITIONING.ks',         '/kick/c47x64/ks/mc2-md_raid1_sda_sdb-PARTITIONING.ks',         '644', 'root.root');
file('kickstart/c48x64/mc2-example-ROOTPW.ks',                        '/kick/c47x64/ks/mc2-example-ROOTPW.ks',                        '644', 'root.root');
file('kickstart/kick-config.pl.example',                              '/kick/kick-config.pl',                                         '644', 'root.root');
file('kickstart/kick-ethers.pl.example',                              '/kick/kick-ethers.pl',                                         '644', 'root.root');
# kickstart, web
file('kickstart/web-conf/kick.conf',                          '/etc/httpd/conf.d/kick.conf',                          '644', 'root.root');
file('kickstart/web-conf/yum.conf',                           '/etc/httpd/conf.d/yum.conf',                           '644', 'root.root');
file('kickstart/web-site/kick.pl',                            '/var/www/sites/kick/kick.pl',                          '755', 'root.root');
nofile('/etc/httpd/conf.d/welcome.conf');
# kickstart, pxe. pxelinux.0 and menu.c32 are from syslinux 3.11 (2.11 in EL4)
file('kickstart/pxe/menu.c32',                                '/tftpboot/menu.c32',                                   '644', 'root.root');
file('kickstart/pxe/pxelinux.0',                              '/tftpboot/pxelinux.0',                                 '644', 'root.root');
file('kickstart/pxe/pxelinux.cfg-default',                    '/tftpboot/pxelinux.cfg/default',                       '644', 'root.root');
service('tftp', 'on', undef);
# nfs
file('nfs/exports.mgmt',              '/etc/exports',                        '644', 'root.root');
service('nfs', 'on', 'restart');
# web
file('apache/empty_index.html',       '/var/www/index.html',                 '644', 'root.root');
file('apache/_default.conf.example',  '/etc/httpd/conf.d/_default.conf',     '644', 'root.root');
service('httpd', 'on', 'restart');
# mrepo
file('mrepo/mrepo.conf',              '/etc/mrepo.conf',                     '644', 'root.root');
file('mrepo/3rdparty-el4.conf',       '/etc/mrepo.conf.d/3rdparty-el4.conf', '644', 'root.root');
file('mrepo/wayf-el4.conf',           '/etc/mrepo.conf.d/wayf-el4.conf',     '644', 'root.root');
file('mrepo/centos48.conf',           '/etc/mrepo.conf.d/centos48.conf',     '644', 'root.root');
#
file('mysql/cron.mysql_purge_binary_logs.$cluster',   '/etc/cron.d/mysql_purge_binary_logs',    '644', 'root.root');
# Make sure that we have a nice max_loop value so we can't mount lots of ISOs if needed
# Don't want a version controlled modprobe.conf since they differ depending on hardware
shell("if ! grep -q max_loop /etc/modprobe.conf; then echo 'options loop max_loop=64' >> /etc/modprobe.conf; fi");
# some configs are missing here, but are in the wfconf directory, eg ganglia files
EOF
;

# configs per role
$role_configs{'common'}                   = [
     'generic_server', 'db_client',
];
$role_configs{'mc2_node_be'}                 = [ @{$role_configs{'common'}},
     'mc2_server_common', 'mc2_server_be',
];
$role_configs{'mc2_node_fe'}                 = [ @{$role_configs{'common'}},
     'mc2_server_common', 'mc2_server_be', 'mc2_server_fe',
];
$role_configs{'mc2_node_dedicated_fe'}                 = [ @{$role_configs{'common'}},
     'mc2_server_common', 'mc2_server_fe',
];
$role_configs{'dedicated_web_node'}       = [ @{$role_configs{'common'}},
     'mc2_server_common', 'dedicated_web_server',
];
$role_configs{'dedicated_db_master_node'} = [ @{$role_configs{'common'}},
     'dedicated_db_server', # configs for master role removed in OSS example
];

$role_configs{'dedicated_db_slave_node'}  = [ @{$role_configs{'common'}},
     'dedicated_db_server', #role_config for dedicated slave removed in OSS example
];
$role_configs{'management_node'}          = [ @{$role_configs{'common'}},
     'mc2_server_common', 'management_server',
];

$roles{'management_node'}          = ['mgmt1'];
$roles{'mc2_node_fe'}              = ['node1', 'node2'];
$roles{'mc2_node_be'}              = ['node3', 'node4', 'node5'];
$roles{'dedicated_web_node'}       = ['web1','web2'];
$roles{'dedicated_db_master_node'} = ['master'];
$roles{'dedicated_db_slave_node'}  = ['slave'];

#print STDERR "Dump wfconf " . Data::Dumper->Dump([\%roles], ['*roles']) . "\n";

debug_print(2, "DEBUG [wfconf] All config done\n");
generate();
