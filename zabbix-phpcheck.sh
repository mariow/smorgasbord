#!/bin/bash

# zabbix-phpcheck.sh
# Let zabbix check if certain php extensions are loaded and ini parameters set
# 
# Mario Witte <mario.witte@chengfu.net>
#
#
# Usage:
#UserParameter=php.mbstring,/$path/zabbix-phpcheck.sh module mbstring
#UserParameter=php.short_open_tag,/$path/zabbix-phpcheck.sh ini short_open_tag

rtype=$1
request=$2

command=""
if [ $rtype == "module" ]; then
	command="extension_loaded";
elif [ $rtype == "ini" ]; then
	command="ini_get";
fi;

if [ $command != "" -a $request != "" ]; then
	`which php` -r "echo $command('$request');";
else
	echo -n -1;
fi;
