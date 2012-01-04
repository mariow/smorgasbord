#!/usr/bin/perl

# This will make stats from php-fpm available in Zabbix.

# Set up php-fpm like this:
# pm.status_path = /phpfpm_status

# Add the following lines to /etc/zabbix_agentd.conf:
# UserParameter=phpfpm.accepted_conn,/etc/zabbix/scripts/zabbix-phpfpm.pl http://localhost 0
# UserParameter=phpfpm.idle_procs,/etc/zabbix/scripts/zabbix-phpfpm.pl http://localhost 1
# UserParameter=phpfpm.active_procs,/etc/zabbix/scripts/zabbix-phpfpm.pl http://localhost 2
# UserParameter=phpfpm.total_procs,/etc/zabbix/scripts/zabbix-phpfpm.pl http://localhost 3
# UserParameter=phpfpm.listenqueue_len,/etc/zabbix/scripts/zabbix-phpfpm.pl http://localhost 4
# UserParameter=phpfpm.maxchildren_reached,/etc/zabbix/scripts/zabbix-phpfpm.pl http://localhost 5
#
# You can then access the new items in Zabbix via phpfpm.accepted_conn, phpfpm.idle_procs etc. 
#

my $host = $ARGV[0];
my $cmd = 'curl -A "Mozilla/4.0 (compatible; cURL; Zabbix)" -m 12 -s -L -k -H "Pragma: no-cache" -H "Cache-control: no-cache" -H "Connection: close" "'.$host.'/phpfpm_status"';
my $server_status = qx($cmd);

my $conn = my $idle = my $active = my $total = my $maxchildren = 0;
foreach (split(/\n/, $server_status)) {
         $conn = $1 if (/^accepted conn:\s+(\d+)/);
         $idle = $1 if (/^idle processes:\s+(\d+)/);
         $active = $1 if (/^active processes:\s+(\d+)/);
         $total = $1 if (/^total processes:\s+(\d+)/);
         $listenqueue = $1 if (/^listen queue len:\s+(\d+)/);
         $maxchildren = $1 if (/^max children reached:\s+(\d+)/);
}

my @phpfpm_checks;
$phpfpm_checks[0] = $conn;
$phpfpm_checks[1] = $idle;
$phpfpm_checks[2] = $active;
$phpfpm_checks[3] = $total;
$phpfpm_checks[4] = $listenqueue;
$phpfpm_checks[5] = $maxchildren;
print "$phpfpm_checks[$ARGV[1]]";
exit(0);
