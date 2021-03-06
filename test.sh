#!/bin/bash

set -u -o pipefail

pcatc=./pcatc

for file in $@; do
	printf "[$file]\n"
	logfile=`basename $file`-log.txt
	$pcatc $file 2>&1 >&- >/dev/null | lli |& tee $logfile
	if [ $? -eq 0 ]; then
		echo -e "\033[1;32mPASS!\033[0m"
		rm $logfile
	else
		echo -e "\033[1;31mFAIL!\033[0m see $logfile for more information"
	fi
done
