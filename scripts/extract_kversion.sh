#!/bin/sh

# extract the kernel version out of the previous extracted version
# information.
# Here kernel version is NOT what's printed on 'uname'.
# we try to get the version of the kernel sources available on
# kernel.org

# first parameter: file containing kernel version string
# second parameter: where to put the gcc version

scriptpath="$(dirname $0)"
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
		echo "$(basename $0): can't access $in" >&2
		exit 1
	fi

	# now try to identify the kernel provider
	if [ $(grep -c "Ubuntu" "${in}") -ne 0 ];
	then
		# ubuntu kernel
		version=$(${scriptpath}/Ubuntu.sh "${in}" "kernel")
	elif [ $(grep -c "\-pve" "${in}") -ne 0 ];
	then
		# Proxmox kernel
		version=$(${scriptpath}/pve.sh "${in}" "kernel")
	elif [ $(grep -c "Debian" "${in}") -ne 0 ];
	then
		# Debian kernel
		version=$(${scriptpath}/Debian.sh "${in}" "kernel")
	else
		# wasn't able to detect the kernel creator
		# exit with error
		echo "$(basename $0): can't detect the kernel creator" >&2
		exit 1
	fi

	if [ $? -ne 0 ];
	then
		echo "$(basename $0): wasn't able to get kernel version" >&2
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
			echo "$(basename $0): wasn't able to create $(dirname "${out}")" >&2
			exit 1
		fi
	fi

	# write the version into the file
	echo "${version}" | sed -n '1p' > ${out}
	if [ $? -ne 0 ];
	then
		# write failed, exit with error
		echo "$(basename $0): wasn't able to create ${out}" >&2
		exit 1
	fi

	echo "#### using kernel version $(echo "${version}" | sed -n '1p') ####" >&2
fi
