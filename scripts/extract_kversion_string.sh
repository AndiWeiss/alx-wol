#!/bin/sh

# this script extracts the kernel version out of a kernel file
# to do so it extracts the vmliux out of the kernel file and
# scans the strings for 'Linux version '
# followed by the expected version numbers

# first parameter: kernel file
# second parameter: path to matching kernel headers
# third parameter: path to temp dir
# fourth parameter: file to create

kernel="$1"
headers="$2"
temp="$3"
versionfile="$4"

major=$(echo "${kernelver}" | sed -n 's|^\([0-9]\{1,\}\).*$|\1|p')
minor=$(echo "${kernelver}" | sed -n 's|^[0-9]\{1,\}\.\([0-9]\{1,\}\).*$|\1|p')

# check if the directory for the emp files exists
if [ ! -d "${temp}" ];
then
	# no, create it
	mkdir -p "${temp}"
	if [ $? -ne 0 ];
	then
		# creation failed, exit with error
		echo "wasn't able to create ${temp}"
		exit 1
	fi
fi

# check if the file to write the version in already exists
if [ ! -f "${versionfile}" ];
then
	# no, create it

	# first step: extract the vmilux out of the kernel file
	# use the script out of the matching kernel sources
	"${headers}/scripts/extract-vmlinux" "${kernel}" > "${temp}/vmlinux"
	if [ $? -ne 0 ];
	then
		# extraction failed, exit with error
		echo "${kernel} seems not to be a vmlinuz file"
		exit 1
	fi

	# now we have the uncompressed vmlinux file
	vmlinux="${temp}/vmlinux"

	# search for a sensefull string in the file
	strings "${vmlinux}" | grep "^Linux version $major\.$minor" > "${versionfile}"

	# check if the file contains a sensefull version string
	i=$(grep -c "^Linux version $major\.$minor" "${versionfile}")
	if [ $i -eq 0 ];
	then
		# no, exite with error
		echo "${vmlinux} seems not to be a vmlinux file"
		rm "${versionfile}"
		exit 1
	fi

	# work done, remove the temporary file
	rm "${temp}/vmlinux"
fi
