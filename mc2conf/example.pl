#!/usr/bin/perl -w

# config for test environment

use MC2Conf;
use strict;
use POSIX qw(strftime);

my $timestamp = strftime "%Y%m%d%H%M%S", localtime;
my %all_nodes = (
   'server1' => { 'fqdn' => 'server1', },
   'server2' => { 'fqdn' => 'server2', },
   'server3' => { 'fqdn' => 'server3', },
   'server4' => { 'fqdn' => 'server4', },
   'server5' => { 'fqdn' => 'server5', },
   'server6' => { 'fqdn' => 'server6', },
);

# it can be convenient to specify lists of servers if they are configured and used differently:
my @frontend_nodes = gen_nodes('server', (1..3));
my @backend_only_nodes = gen_nodes('server', (4..6)); # 
my @nodes = keys %all_nodes;

# common variables
my $version = '1.0.1';
my $path = "/mc2/bin-$version";
my $nav_params = '';
my $log_path = "/logs/";
my $default_server_params  = '--client_settings=' . $path . '/navclientsettings.txt --server_lists=' .
                             $path . '/namedservers.txt --minnumberthreads=30 --maxnumberthreads=30';
my $default_nav_params     = '--boxtype=1 --categories=' . $path . '/wfcat/ ' . $default_server_params;
my $default_testenv_nav_params      = $default_nav_params;
my $default_testenv_nav_http_params = $default_nav_params . ' --httpport=8080';
my $default_testenv_xml_params      = "--port=11199 --unsecport=19911 " .  $default_server_params;

# the different mc2control instances
my $instance='test-com';
my $log_prefix = 'test-com';
my $mc2_prop='/mc2/etc/mc2-testenv.prop';
create_hosts($instance, @nodes);
create_settings($instance, $path);
my $CONFIG = open_and_add_header($instance, $log_path, @nodes);
write_all($CONFIG,        module(add_path($path, 'GfxModule'),   "-p $mc2_prop", $log_prefix, undef, 'Gfx'));
write_all($CONFIG,        module(add_path($path, 'EmailModule'), "-p $mc2_prop", $log_prefix, undef, 'Email'));
write_all($CONFIG,        module(add_path($path, 'TileModule'),  "-p $mc2_prop", $log_prefix, undef, 'Tile'));
write_one($CONFIG, 'server5', module(add_path($path, 'UserModule'),          "-p $mc2_prop -r 20", $log_prefix, undef, 'User'));
write_one($CONFIG, 'server6', module(add_path($path, 'UserModule'),          "-p $mc2_prop -r 10", $log_prefix, undef, 'User'));
write_many($CONFIG, \@backend_only_nodes, module(add_path($path, 'ExtServiceModule'),    "-p $mc2_prop", $log_prefix, undef, 'Ext'));
write_many($CONFIG, \@backend_only_nodes, module(add_path($path, 'CommunicationModule'), "-p $mc2_prop", $log_prefix, undef, 'Com'));
add_footer_and_close($CONFIG);

$instance='test-modemea';
$log_prefix = 'test-modemea';
create_hosts($instance, @backend_only_nodes);
create_settings($instance, $path);
$CONFIG = open_and_add_header($instance, $log_path, @nodes);
write_all($CONFIG, module(add_path($path, 'MapModule'),    "-p $mc2_prop --mapSet=0", $log_prefix, undef, 'Map'));
write_all($CONFIG, module(add_path($path, 'SearchModule'), "-p $mc2_prop --mapSet=0", $log_prefix, undef, 'Srch'));
write_all($CONFIG, module(add_path($path, 'RouteModule'),  "-p $mc2_prop --mapSet=0", $log_prefix, undef, 'Rte'));
write_one($CONFIG, 'server4', module(add_path($path, 'InfoModule'), "-p $mc2_prop --mapSet=0 -r 20", $log_prefix, undef, 'Info'));
write_one($CONFIG, 'server5', module(add_path($path, 'InfoModule'), "-p $mc2_prop --mapSet=0 -r 10", $log_prefix, undef, 'Info'));
add_footer_and_close($CONFIG);

$instance='test-modamericas';
$log_prefix = 'test-modamericas';
create_hosts($instance, @backend_only_nodes);
create_settings($instance, $path);
$CONFIG = open_and_add_header($instance, $log_path, @nodes);
write_all($CONFIG, module(add_path($path, 'MapModule'),    "-p $mc2_prop --mapSet=1", $log_prefix, undef, 'Map'));
write_all($CONFIG, module(add_path($path, 'SearchModule'), "-p $mc2_prop --mapSet=1", $log_prefix, undef, 'Srch'));
write_all($CONFIG, module(add_path($path, 'RouteModule'),  "-p $mc2_prop --mapSet=1", $log_prefix, undef, 'Rte'));
write_one($CONFIG, 'server4', module(add_path($path, 'InfoModule'), "-p $mc2_prop --mapSet=1 -r 20", $log_prefix, undef, 'Info'));
write_one($CONFIG, 'server5', module(add_path($path, 'InfoModule'), "-p $mc2_prop --mapSet=1 -r 10", $log_prefix, undef, 'Info'));
add_footer_and_close($CONFIG);

$instance='test-srv';
$log_prefix = 'test-srv';
create_hosts($instance, @frontend_nodes);
create_settings($instance, $path);
$CONFIG = open_and_add_header($instance, $log_path, @nodes);
write_all($CONFIG, server(add_path($path, 'NavigatorServer'), $default_testenv_nav_http_params . " -p $mc2_prop", $log_prefix . '-HT', undef, 'NavHT'));
write_all($CONFIG, server(add_path($path, 'NavigatorServer'), $default_testenv_nav_params . " -p $mc2_prop", $log_prefix, undef, 'Nav'));
write_all($CONFIG, server(add_path($path, 'XMLServer'),       $default_testenv_xml_params . " -p $mc2_prop", $log_prefix, undef, 'XML'));
add_footer_and_close($CONFIG);
