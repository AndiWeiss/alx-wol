#!/bin/sh

# fetch a single kernel source file

# first parameter:  file to fetch, path in kernel sources
# second parameter: store the file here
# third parameter:  log the fetch in this file
# additionally:
# environment kernver has to be set with the digits of the kernel version
# either format 'x.y' or 'x.y.z'

file="$1"
store="$2"
got_files="$3"

# check if the directory where to store the file exists
dir=$(dirname "${store}")
if [ ! -d "${dir}" ];
then
	# it doesn't exist
	# create it
	mkdir -p "${dir}"
	if [ $? -ne 0 ];
	then
		# error on creation
		# exit with error
		exit 1
	fi
fi

# check if the file already exists
if [ -d "${store}" ];
then
	# yes, remove it
	# may be a directory ...
	rm -rf "${store}"
fi

# get the string required for the version required for
# fetching the file from kernel.org
ldv="v$(echo ${kernver} | sed -n 's|^\([0-9]\{1,\}\.[0-9]\{1,\}\)\.0$|\1|;p')"

# fetch the file
wget -nv -O "${store}" https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/plain/${file}?h=${ldv}
if [ $? -ne 0 ];
then
	# fetch faild!
	# remove the artifacts
	rm "${store}"
	# and exit with error
	exit 1
fi

# log the file as fetched
echo "${file}" | sed -n "s|^${kerneldir}/||p" >> "${got_files}"

exit 0
