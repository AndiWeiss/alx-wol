#!/bin/sh

# first parameter: file containing kernel version string
# second parameter: where to put the gcc version

in="$1"
out="$2"

major=$(echo "${kernelver}" | sed -n 's|^\([0-9]\{1,\}\).*$|\1|p')
minor=$(echo "${kernelver}" | sed -n 's|^[0-9]\{1,\}\.\([0-9]\{1,\}\).*$|\1|p')

if [ ! -f "${out}" ];
then
	if [ ! -f "${in}" ];
	then
		echo "can't access $in"
		exit 1
	fi
	if [ $(grep -c " $major\.$minor\.[0-9]\{1,\})$" "${in}") -ne 0 ];
	then
		# regular ubuntu kernel
		# contains e.g.
		# (Ubuntu 6.2.0-39.40~22.04.1-generic 6.2.16)
		# at the end of the version string
		version=$(cat "${in}" | sed -n "s|^.* \($major\.$minor\.[0-9]\{1,\}\))$|\1|p")
	else
		if [ $(grep -c "Linux version $major\.$minor\.[0-9]\{1,\}.*$" "${in}") -ne 0 ];
		then
			# ubuntu kernel from
			# https://kernel.ubuntu.com/mainline/
			# seems to always start with
			# Linux version 5.19.16-051916-generic
			version=$(cat "${in}" | sed -n "s|^Linux version \($major\.$minor\.[0-9]\{1,\}\).*$|\1|p")
		else
			echo "can't detect the kernel version"
			exit 1
		fi
	fi

	if [ ! -d "$(dirname "${out}")" ];
	then
		mkdir -p "$(dirname "${out}")"
		if [ $? -ne 0 ];
		then
			echo "wasn't able to create $(dirname "${out}")"
			exit 1
		fi
	fi

	echo "${version}" | sed -n '1p' > ${out}
	if [ $? -ne 0 ];
	then
		echo "wasn't able to create ${out}"
		exit 1
	fi
fi
