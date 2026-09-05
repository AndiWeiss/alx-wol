#!/usr/bin/bash

count=0
while [ $count -lt 10 ]; do
	/usr/bin/nslookup git.kernel.org
	if [ $? -eq 0 ]; then
		/usr/sbin/dkms $*
		exit $?
	fi
	sleep 1

	count=$(expr $count + 1)
done

exit 1
