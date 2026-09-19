#!/usr/bin/bash

repo_path="LOCAL_LINUX_REPO"
logfile="/var/log/kernelfetcher.log"

current_time=$(/usr/bin/date +%s)
prev_time=$(/usr/bin/stat -c %Y "${repo_path}/.git/FETCH_HEAD")

diff_time=$(/usr/bin/expr ${current_time} - ${prev_time})

# seconds for one day: 60 * 60 * 24 = 86400
if [ ${diff_time} -gt 86400 ]; then
	echo "-------------- executed $(date +"%F %T") ${repo_path} --------------" >> ${logfile}
	count=0
	while [ $count -lt 10 ]; do
		/usr/bin/nslookup git.kernel.org
		if [ $? -eq 0 ]; then
			owner=$(/usr/bin/stat -c %U "${repo_path}")
			/usr/bin/su -l ${owner} -c "/usr/bin/git -C \"${repo_path}\" fetch" >> ${logfile} 2>&1
			exit $?
		fi
		sleep 1

		count=$(/usr/bin/expr $count + 1)
	done

	echo "timeout while waiting for network" >> ${logfile}
	exit 1
fi

exit 0
