#!/usr/bin/perl -w

package WFConf;

use strict;
use Getopt::Std;
use Sys::Hostname;
use Data::Dumper;

use vars qw(@ISA @EXPORT @EXPORT_OK %config %role_configs %roles $host $full_host $cluster $arch $config_file_dir);
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(packages file_system file perms noderoles nofile dir shell service group user generate debug_print $debug_level %config %role_configs %roles $host $full_host $cluster $arch $config_file_dir);

use vars qw(
         $opt_d $opt_v $opt_s
);

# 
# debug level used by debug_print
#
my $debug_level = 8;

getopts('d:vs:');
my $verbose = 0;

if (defined($opt_v)) {
   $verbose = 1;
}

if (defined($opt_d)) {
   $debug_level = $opt_d;
}

# a silly default value, needs to be set in the config script
$config_file_dir = '.';

# predefined variables that is (can) be used in the config file
# hostname (short version)
if (defined($ENV{'CONF_FORCE_HOSTNAME'})) {
   $full_host = $ENV{'CONF_FORCE_HOSTNAME'};
} else {
   $full_host = hostname;
}
$host = $full_host;
$host =~ s/\..*$//;
$cluster = $full_host;
$cluster =~ s/^.*\.//;
if ($cluster eq 'cluster')
{
   $cluster = 'wf-eu';
}
debug_print(1, "DEBUG [WFConf] full_host: $full_host\n");
debug_print(1, "DEBUG [WFConf] host: $host\n");
debug_print(1, "DEBUG [WFConf] cluster: $cluster\n");
if (defined($ENV{'CONF_FORCE_ARCH'})) {
   $arch = $ENV{'CONF_FORCE_ARCH'};
} else {
   $arch = `uname -i`;
}
chomp $arch;
debug_print(1, "DEBUG [WFConf] arch: $arch\n");

# configuration hashes
%config = ();
%role_configs = ();
%roles = ();

# config elements
my @file_system = ();
my @files = ();
my @perms = ();
my @nofiles = ();
my @dirs = ();
my @packages = ();
my @services = ();
my @shell = ();
my @users = ();
my @groups = ();
my @noderoles = ();

my %generators = (
   'gen_noderoles'   => \&gen_noderoles,
   'gen_group'       => \&gen_group,
   'gen_user'        => \&gen_user,
   'gen_file_system' => \&gen_file_system,
   'gen_nofile'      => \&gen_nofile,
   'gen_packages'    => \&gen_packages,
   'gen_dir'         => \&gen_dir,
   'gen_file'        => \&gen_file,
   'gen_perms'       => \&gen_perms,
   'gen_nofile'      => \&gen_nofile,
   'gen_service'     => \&gen_service,
   'gen_shell'       => \&gen_shell,
);

# subs that are exported and called by the config script

#
# Debug print helper
#
sub debug_print
{
   my $this_debug_level = shift;
   ($this_debug_level <= $debug_level) || return;
   print STDERR localtime() . " ", @_;
}

sub packages
{
   debug_print(4, "DEBUG packages() called, with args: " . join (', ', @_) . "\n");
   push @packages, @_;
   return 1;
}

sub file_system
{
   debug_print(4, "DEBUG file_system() called with args: " . join(', ', @_) . "\n");
   push @file_system, [@_];
   return 1;
}

sub file
{
   push @files, [@_];
   return 1;
}

sub perms
{
   push @perms, [@_];
   return 1;
}

sub nofile
{
   push @nofiles, @_;
   return 1;
}

sub dir
{
   push @dirs, [@_];
   return 1;
}

sub service
{
   push @services, [@_];
   return 1;
}

sub shell
{
   push @shell, @_;
   return 1;
}

sub group
{
   push @groups, [@_];
   return 1;
}

sub user
{
   push @users, [@_];
   return 1;
}

sub noderoles
{
   push @noderoles, @_;
   return 1;
}

sub generate
{
   my %generated_confs = ();
   my $this_host = $host;
   my $this_host_id = $host;
   $this_host_id =~ s/.*-//;
   if ($this_host_id =~ m/^\d$/) { # single digit? Then we should not use the stripped version
      $this_host_id = $host;
   }

   debug_print(1, "DEBUG Generating for $this_host_id\n");

   debug_print(1, "DEBUG Roles: " . join (',', keys %roles) . "\n");
#   print STDERR "Dump generate() " . Data::Dumper->Dump([\%roles], ['*roles']) . "\n";
   foreach my $role (keys %roles) {
      debug_print(4, "DEBUG Checking role $role\n");
      if (grep (/$this_host_id$/, @{$roles{$role}})) {
         debug_print(4, "DEBUG $this_host_id matches $role\n");
         foreach my $conf (@{$role_configs{$role}}) {
            if (!defined($generated_confs{$conf})) {
               $generated_confs{$conf} = 1;
               debug_print(4, "DEBUG Evaling config $conf\n");
               debug_print(8, "DEBUG Code to eval is:\n" . $config{$conf});
               eval $config{$conf} || die "FATAL: Eval of $conf failed: $@";
            } else {
               debug_print(4, "DEBUG Not evaling config $conf, already handled\n");
            }
         }
      }
   }

   debug_print(4, "DEBUG Generating config\n");
   if ( !defined($opt_s) ) {
      gen_pre();
      gen_noderoles();
      gen_group();
      gen_user();
      gen_file_system();
      gen_nofile();
      gen_packages();
      gen_dir();
      gen_file();
      gen_perms();
      gen_nofile(); # nofile twice to get rid of any crap before gen_packages and later to remove it immediately if it reappears. Not pretty and possible not necessary.
      gen_service();
      gen_shell();
   } else {
      gen_pre();
      if ( defined($generators{$opt_s}) ) {
         &{$generators{$opt_s}};
      } else {
         print "echo error: undefined generator method\n";
      }
   }
}

# subs that generate the shell script that is output
sub gen_pre
{
   my $user = $ENV{'LOGNAME'};
   if (!defined($user)) {
      $user = 'N/A';
   }
   print "#!/bin/zsh\n";
   print "#\n# Generated by WFConf at " . localtime() . " on $host / " . hostname . " by $user\n\n";
   print "echo WFConf -- Starting\n";
}

sub gen_file_system
{
   print "# file_system\n";
   print "echo WFConf -- File systems\n";
   # this should be sorted by mountpoint to make sure that they are created in the correct order!
   foreach my $file_system (@file_system) {
      my ($id, $mount_point, $size, $owner, $mode, $fs_type, $ext3_inodes) = @$file_system;
      my ($vg, $lv) = split "/", $id;
      print "# $id ($vg, $lv) mounted at $mount_point, with size $size.\n# Owner $owner and mode $mode.\n# File system $fs_type (ext3 only: $ext3_inodes)\n";
      print
<<EOF 
      if [[ ! -e /dev/$id ]]; then
         /usr/sbin/lvcreate -v -n $lv -L $size $vg
EOF
;
      if ($fs_type eq 'ext3') {
         print
<<EOF 
         /sbin/mke2fs -v -j -N $ext3_inodes /dev/$id
         /sbin/tune2fs -c0 -i 0 /dev/$id
EOF
;
      } elsif ($fs_type eq 'reiserfs') {
         print
<<EOF 
         /sbin/mkreiserfs -f -f /dev/$id
EOF
;
      } elsif ($fs_type eq 'xfs') {
         print
<<EOF 
         /sbin/mkfs.xfs -f /dev/$id
EOF
;
      }
      print
<<EOF 
         echo "/dev/$id      $mount_point      $fs_type     defaults 1 2" >> /etc/fstab
      fi
EOF
;
      print
<<EOF 
      if /usr/sbin/lvextend -t -L $size $id > /dev/null 2>&1 ; then
          /usr/sbin/lvextend -v -L $size $id
EOF
;
      if ($fs_type eq 'ext3') {
         print "           /usr/sbin/ext2online /dev/$id\n";
      } elsif ($fs_type eq 'reiserfs') {
         print "           /sbin/resize_reiserfs /dev/$id\n";
      }
      print "       fi\n";
      print
<<EOF
      if [[ ! -d $mount_point ]]; then
         /bin/mkdir -v -p $mount_point
      fi
      if ! grep $id /proc/mounts; then
         /bin/mount -v $mount_point
      fi
      if [[ `/usr/bin/stat -c \%a.\%U.\%G $mount_point` != $mode.$owner ]] ; then
         /bin/chown -v $owner $mount_point
         /bin/chmod -v $mode $mount_point
      fi
      # fix any contexts with restorecon
      /sbin/restorecon -v $mount_point
EOF
;
   }
   print "\n";

}

sub gen_file
{
   print "# file\n";
   print "echo WFConf -- Files\n";
   foreach my $file (@files) {
      my ($source, $dest, $mode, $owner_group) = @$file;
      # copy if neeeded using install
      my ($owner, $group) = split (/\./, $owner_group);
      print "# $source at $dest, with mode $mode, owner $owner and group $group\n";
      print
<<EOF
      /usr/bin/install --verbose -D -C --preserve-timestamps --mode $mode --owner $owner --group $group $config_file_dir/$source $dest
EOF
;
   # fix any contexts with restorecon
      print
<<EOF
      /sbin/restorecon -v $dest
EOF
;
   }
   print "\n";
}

sub gen_perms
{
   print "# perms\n";
   print "echo WFConf -- Permissions\n";
   foreach my $perm (@perms) {
      my ($file, $mode, $owner_group) = @$perm;
      print "# $file should have mode $mode, owned by $owner_group\n";
      print
<<EOF
      /bin/chown -c $owner_group $file
      /bin/chmod -c $mode $file
EOF
;
      # fix any contexts with restorecon
      print
<<EOF
      /sbin/restorecon -v $file
EOF
;
   }
   print "\n";
}

sub gen_nofile
{
   print "# nofile\n";
   print "echo WFConf -- No Files\n";
   foreach my $nofile (@nofiles) {
      # remove with rm if exists
      print
<<EOF
      if [[ -e $nofile ]]; then
         rm -vf $nofile
      fi
EOF
   }
}

sub gen_dir
{
   print "# dir\n";
   print "echo WFConf -- Directories\n";
   foreach my $dir (@dirs) {
      my ($dest, $mode, $owner_group) = @$dir;
      # create if needed using install
      my ($owner, $group) = split (/\./, $owner_group);
      print "# $dest, with mode $mode, owner $owner and group $group\n";
      print
<<EOF
      /usr/bin/install --verbose -d -C --mode $mode --owner $owner --group $group $dest
EOF
;
   # fix any contexts with restorecon
      print
<<EOF
      /sbin/restorecon -R -v $dest
EOF
;
   }
   print "\n";
}

sub gen_packages
{
   print "# packages\n";
   print "echo WFConf -- Packages\n";
   foreach my $pkg (@packages) {
# this doesn't work if foo.x86_64 is installed and you want foo.i386 as well. (yes, it's stupid)
#      print
#<<EOF
#      if ! /bin/rpm -q $pkg > /dev/null; then
#         export PACKAGES="\$PACKAGES $pkg"
#      fi
#EOF
#;
      print
<<EOF
      if  [[ "`/bin/rpm -q $pkg`" == "" || \$? -ne 0 ]]; then
         export PACKAGES="\$PACKAGES $pkg"
      fi
EOF
;
   }
   print
<<EOF
      if [[ "\$PACKAGES" != "" ]]; then
         echo WFConf -- Installing/upgrading: \$PACKAGES
         /usr/bin/yum -y install \${=PACKAGES}
      fi
EOF
;
   print "\n";
}

sub gen_service
{
   print "# service\n";
   print "echo WFConf -- Services\n";
   foreach my $service (@services) {
      my ($service_id, $chkconfig, $action) = @$service;
      print "      /sbin/chkconfig $service_id $chkconfig\n";
      if (defined($action)) {
         print "      /sbin/service $service_id $action\n";
      }
   }
   print "\n";
}

sub gen_group
{
   print "# group\n";
   print "echo WFConf -- Groups\n";
   foreach my $group (@groups) {
      my ($name, $gid) = @$group;
      my $params = '';
      if (defined $gid) {
         $params .= " -g $gid";
      }
      print
<<EOF
      /usr/sbin/groupadd $params $name
EOF
   }
   print "\n";
}

sub gen_user
{
   print "# user\n";
   print "echo WFConf -- Users\n";
   foreach my $user (@users) {
      my ($name, $uid, $home, $shell, $grouplist, $extra_param) = @$user;
      my $params = '';
      my ($group_primary, $group_extra);
      if (defined $grouplist) {
         ($group_primary, $group_extra) = split(/,/, $grouplist, 2); }
      if (defined $group_primary) {
         $params .= " -g $group_primary"; }
      if (defined $group_extra) {
         $params .= " -G $group_extra"; }
      if (defined $uid) {
         $params .= " -u $uid"; }
      if (defined $home) {
         $params .= " -d $home"; }
      if (defined $shell) {
         $params .= " -s $shell"; }
      if (defined $group_primary) {
         $params .= " -s $shell"; }
      if (defined $extra_param) {
         $params .= " $extra_param"; }
      print
<<EOF
      /usr/sbin/useradd $params $name
EOF
   }
   print "\n";
}

sub gen_shell
{
   print "# shell\n";
   print "echo WFConf -- Shell\n";
   foreach my $s (@shell) {
      print "      $s\n";
   }
   print "\n";
}

sub gen_noderoles
{
   my %nodes = ();
   foreach my $role (keys %roles) {
      foreach my $node (@{$roles{$role}}) {
         $nodes{$node}{$role} = 1;
         foreach my $subrole (@{$role_configs{$role}}) {
            $nodes{$node}{$subrole} = 1;
         }
      }
   }
   print "# noderoles\n";
   print "echo WFConf -- Node Roles File\n";
   foreach my $noderolesfile (@noderoles) {
      print "echo '# WFConf generated Node Roles File' > $noderolesfile\n";
      foreach my $node (sort keys %nodes) {
         print "echo '".$node.' '.join(' ',keys %{$nodes{$node}})."' >> $noderolesfile\n";
      }
   }
   print "\n";
}

return 1;
