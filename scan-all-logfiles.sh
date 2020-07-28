#!/usr/bin/env bash

for logfile in /var/log/messages*
do
	echo
	echo "################  $logfile #######################"
	echo 
	./log-filter.sh log-filter.rules $logfile
done

