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
		echo "$(basename $0): wasn't able to create ${temp}" >&2
		exit 1
	fi
fi

# check if the file to write the version in already exists
if [ ! -f "${versionfile}" ];
then
	# no, create it

	# first step: extract the vmilux out of the kernel file
	# use the script out of the matching kernel sources
	if [ -x "${headers}/scripts/extract-vmlinux" ];
	then
		# the extract script has been found
		# use it
		"${headers}/scripts/extract-vmlinux" "${kernel}" > "${temp}/vmlinux"
	else
		# the extract script has not been found!
		# fetch the script for the currently running version
		wget -nv -O "${temp}/extract-vmlinux" https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/plain/scripts/extract-vmlinux?h=v$(uname -r | sed -n 's|\.[^.]*$||p')
		if [ $? -ne 0 ];
		then
			# exit if it can't be fetched
			echo "$(basename $0): no extract-vmlinux available" >&2
			exit 1
		else
			# use it
			chmod +x "${temp}/extract-vmlinux"
			"${temp}/extract-vmlinux" "${kernel}" > "${temp}/vmlinux"
		fi
	fi

	if [ $? -ne 0 ];
	then
		# extraction failed, exit with error
		echo "$(basename $0): ${kernel} seems not to be a vmlinuz file" >&2
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
		echo "$(basename $0): ${vmlinux} seems not to be a vmlinux file" >&2
		rm "${versionfile}"
		exit 1
	fi

	# work done, remove the temporary file
	rm "${temp}/vmlinux"
fi
