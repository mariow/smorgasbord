<?php

/****************************************************************************
mysql-slave-checkweb.php 0.1
Copyright 2011 Mario Witte

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

Report bugs to: mario.witte@chengfu.net

02/25/2011 v0.1
****************************************************************************/


/* settings */
$mysql_host = 'localhost'; // host:port or socket path
$mysql_user = 'root';
$mysql_pass = '';

/* operations */
/* DON'T CHANGE ANYTHING BELOW THIS LINE */

// mysql connect
$dbh = mysql_connect($mysql_host, $mysql_user, $mysql_pass);
if (!$dbh) {
	ex("CRITICAL", "cannot connect to $mysql_host");
}
$query = 'SHOW SLAVE STATUS';
$result = mysql_query($query, $dbh);
$resultset = mysql_fetch_assoc($result);
if (sizeof($resultset) <= 1) {
	ex("CRITICAL", "no slave seems to be running");
}

$ok_io = ($resultset['Slave_IO_Running'] == 'Yes' ? true : false);
$ok_sql = ($resultset['Slave_SQL_Running'] == 'Yes' ? true : false);
$delay = $resultset['Seconds_Behind_Master'];

if ($ok_io and $ok_sql and $delay < 60) {
	ex("OK", "");
} elseif ($ok_io and $ok_sql and $delay >= 60) {
	ex("WARNING", "slave running, but has a delay of $delay seconds");
} else {
	ex("CRITICAL", "slave stopped: IO ".($ok_io ? 'running' : 'stopped').', SQL '.($ok_sql ? 'running' : 'stopped'));
}

exit;

function ex($state, $msg) {
	echo $state.($msg ? ' - '.$msg : '');
	exit;
}
