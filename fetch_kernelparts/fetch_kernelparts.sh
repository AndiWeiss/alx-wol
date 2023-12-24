#!/bin/sh

# parameter:
# $1: kernel version (e.g. v6.5.13)
# $2: file containing the files to fetch
# $3: directory where to put them

fetch_file="$(dirname "$0")/fetch_single_file.sh"
export fetch_file
fetch_dir="$(dirname "$0")/fetch_dir.sh"
export fetch_dir

if [ $# -ne 3 ];
then
	echo "$(basename $0) expects 3 parameters:"
	echo "first  parameter: kernel version to fetch from (eg v6.5.13)"
	echo "second parameter: file containing the files to fetch"
	echo "third  parameter: directory where to put them"
	exit 1
fi

kernver="$1"
export kernver
config="$2"
writeto="$3"

if [ -f "${config}" ];
then
	i=$(sed -n 's|^[[:space:]]*||g;p' "${config}" | grep -c '^[^#].*/[[:space:]]*$')
	if [ ${i} -ne 1 ];
	then
		echo "there has to be exactly one line ending with a slash in ${config}"
		exit 1
	fi
else
	echo "file ${config} doesn't exist"
	exit 1
fi

kerneldir=$(sed -n 's|^[[:space:]]*||g;p' "${config}" | grep '^[^#].*/[[:space:]]*$')
kerneldir=$(echo "${kerneldir}" | sed -n "s|^[[:space:]]*\(.*\)/[[:space:]]*$|\1|p")
echo "kerneldir: >$kerneldir<"

if [ ! -d "${writeto}" ];
then
	mkdir -p "${writeto}"
	if [ $? -ne 0 ];
	then
		exit 1
	fi
fi

while read line
do
	i=$(echo "$line" | grep -c "^[^#].*[^/]$")
	if [ ${i} -eq 1 ];
	then
		file=${line}
		i=$(echo "$file" | grep -c "/")
		if [ ${i} -eq 1 ];
		then
			mkdir -p $(dirname "${writeto}/${file}")
			if [ $? -ne 0 ];
			then
				exit 1
			fi
		fi
		${fetch_file} "${kerneldir}/${file}" "${writeto}/${file}"
		if [ $? -ne 0 ];
		then
			exit 1
		fi
		i=$(grep -c "^<html><head><title>/${kerneldir}/${file}/</title></head>$" ${writeto}/${file})
		if [ ${i} -ne 0 ];
		then
			${fetch_dir} "${kerneldir}/${file}" "${writeto}/${file}"
		fi
	fi
done < "${config}"
