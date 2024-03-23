#!/bin/sh

# extract the kernel version out of the previous extracted version
# information.
# Here kernel version is NOT what's printed on 'uname'.
# we try to get the version of the kernel sources available on
# kernel.org

# first parameter: file containing kernel version string
# second parameter: where to put the gcc version

in="$1"
out="$2"

# in ubuntu systems kernelver contains the major and minor
# version from kernel.org.
# The patch level is not included.
major=$(echo "${kernelver}" | sed -n 's|^\([0-9]\{1,\}\).*$|\1|p')
minor=$(echo "${kernelver}" | sed -n 's|^[0-9]\{1,\}\.\([0-9]\{1,\}\).*$|\1|p')

# check if the output is already available
if [ ! -f "${out}" ];
then
	# no, create it

	# check if the file containing the complete version string is
	# accessable
	if [ ! -f "${in}" ];
	then
		# no, exit with error
		echo "can't access $in"
		exit 1
	fi

	# now try to identify the patch level
	if [ $(grep -c " $major\.$minor\.[0-9]\{1,\})$" "${in}") -ne 0 ];
	then
		# regular ubuntu kernel
		# contains e.g.
		# (Ubuntu 6.2.0-39.40~22.04.1-generic 6.2.16)
		# at the end of the version string
		version=$(cat "${in}" | sed -n "s|^.* \($major\.$minor\.[0-9]\{1,\}\))$|\1|p")
	elif [ $(grep -c "Linux version $major\.$minor\.[0-9]\{1,\}.*$" "${in}") -ne 0 ];
	then
		# ubuntu kernel from
		# https://kernel.ubuntu.com/mainline/
		# seems to always start with
		# Linux version 5.19.16-051916-generic
		version=$(cat "${in}" | sed -n "s|^Linux version \($major\.$minor\.[0-9]\{1,\}\).*$|\1|p")
	else
		# wasn't able to detect the kernel version
		# exit with error
		echo "can't detect the kernel version"
		exit 1
	fi

	# check if the directory for the version file exists
	if [ ! -d "$(dirname "${out}")" ];
	then
		# no, create it
		mkdir -p "$(dirname "${out}")"
		if [ $? -ne 0 ];
		then
			# creation failed, exit with error
			echo "wasn't able to create $(dirname "${out}")"
			exit 1
		fi
	fi

	# write the version into the file
	echo "${version}" | sed -n '1p' > ${out}
	if [ $? -ne 0 ];
	then
		# write failed, exit with error
		echo "wasn't able to create ${out}"
		exit 1
	fi
fi
