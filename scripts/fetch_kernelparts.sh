#!/bin/sh

# fetch files and directories from kernel.org

# parameter:
# $1: kernel version (e.g. 6.5.13)
# $2: file containing the files to fetch
# $3: directory where to put them
# $4: file to list all fetched files

# script to fetch a single file
fetch_file="$(dirname "$0")/fetch_single_file.sh"
export fetch_file

# script to fetch a directory
fetch_dir="$(dirname "$0")/fetch_dir.sh"
export fetch_dir

# script to read a tag from config file
read_tag="$(dirname "$0")/read_tag.sh"

# check for correct number of parameters
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

# check if the config file exists
if [ ! -f "${config}" ];
then
	# it doesn't, exit with error
	echo "file ${config} doesn't exist"
	exit 1
fi

# get the kernel source base directory
kerneldir="$("${read_tag}" "${kernver}" kerneldir 1 "${config}")"
export kerneldir

# check if the destination directory exists
if [ ! -d "${writeto}" ];
then
	# it doesn't, create it
	mkdir -p "${writeto}"
	if [ $? -ne 0 ];
	then
		# creation failed, exit with error
		exit 1
	fi
fi

# get the information which files to fetch out of the config file
all_files="$("${read_tag}" "${kernver}" files 0 "${config}")"
end=$(echo "${all_files}" | wc -l)
cur=0

# loop over the file list
while [ $cur -lt $end ];
do
	cur=$(expr $cur + 1)
	line="$(echo "${all_files}" | sed -n "${cur}p")"

	# get one file to fetch
	file=${line}

	# check if it is a file or a complete path
	i=$(echo "$file" | grep -c "/")
	if [ ${i} -eq 1 ];
	then
		# it's a path, create the destination path
		mkdir -p $(dirname "${writeto}/${file}")
		if [ $? -ne 0 ];
		then
			# path creation failed, exit with error
			exit 1
		fi
	fi

	# fetch a single file
	${fetch_file} "${kerneldir}/${file}" "${writeto}/${file}" "${got_files}"
	if [ $? -ne 0 ];
	then
		# fetch failed, exit with error
		exit 1
	fi

	# check if the file contains a http link inside the kernel tree
	i=$(grep -c "^<html><head><title>/${kerneldir}/${file}/</title></head>$" ${writeto}/${file})
	if [ ${i} -ne 0 ];
	then
		# yes, so this is not a file but a directory
		# fetch the complete directory
		"${fetch_dir}" "${kerneldir}/${file}" "${writeto}/${file}" "${got_files}"
		if [ $? -ne 0 ];
		then
			# fetching failed, exit with error
			exit 1
		fi
	fi
done
