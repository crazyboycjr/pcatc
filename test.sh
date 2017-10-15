#!/bin/bash

pcatc=obj/pcatc

for file in $@; do
	printf "[$file]"
	logfile=`basename $file`-log.txxt
	$pcatc $file | tee $logfile
	if [ $? -eq 0 ]; then
		echo -e "\033[1;32mPASS!\033[0m"
		rm $logfile
	else
		echo -e "\033[1;31mFAIL!\033[0m see $logfile for more information"
	fi
done
