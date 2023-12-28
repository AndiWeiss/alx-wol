#!/bin/sh

# parameter:
# $1: kernel version (e.g. 6.5.13)
# $2: file containing the files to fetch
# $3: directory where to put them
# $4: file to list all fetched files

fetch_file="$(dirname "$0")/fetch_single_file.sh"
export fetch_file
fetch_dir="$(dirname "$0")/fetch_dir.sh"
export fetch_dir

read_tag="$(dirname "$0")/read_tag.sh"

if [ $# -ne 4 ];
then
	echo "$(basename $0) expects 3 parameters:"
	echo "first  parameter: kernel version to fetch from (eg 6.5.13)"
	echo "second parameter: file containing the files to fetch"
	echo "third  parameter: directory where to put them"
	echo "fourth parameter: file to list all fetched files"
	exit 1
fi

kernver="$1"
export kernver
config="$2"
writeto="$3"
got_files="$4"

if [ ! -f "${config}" ];
then
	echo "file ${config} doesn't exist"
	exit 1
fi

kerneldir="$("${read_tag}" "${kernver}" kerneldir 1 "${config}")"
export kerneldir

if [ ! -d "${writeto}" ];
then
	mkdir -p "${writeto}"
	if [ $? -ne 0 ];
	then
		exit 1
	fi
fi

all_files="$("${read_tag}" "${kernver}" files 0 "${config}")"
end=$(echo "${all_files}" | wc -l)
cur=0

while [ $cur -lt $end ];
do
	cur=$(expr $cur + 1)
	line="$(echo "${all_files}" | sed -n "${cur}p")"

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
	${fetch_file} "${kerneldir}/${file}" "${writeto}/${file}" "${got_files}"
	if [ $? -ne 0 ];
	then
		exit 1
	fi
	i=$(grep -c "^<html><head><title>/${kerneldir}/${file}/</title></head>$" ${writeto}/${file})
	if [ ${i} -ne 0 ];
	then
		"${fetch_dir}" "${kerneldir}/${file}" "${writeto}/${file}" "${got_files}"
	fi
done
