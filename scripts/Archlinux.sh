#!/bin/sh

# extract the kernel version out of the Archlinux kernel version
# information.
# Here kernel version is NOT what's printed on 'uname'.
# we try to get the version of the kernel sources available on
# kernel.org

# first parameter: file containing kernel version string
# second parameter: kernel or gcc

in="$1"
what="$2"

if [ "${what}" = "kernel" ];
then
	# in Archlinux systems kernelver contains the major and minor
	# version from kernel.org.
	# The patch level is not included.
	major=$(echo "${kernelver}" | sed -n 's|^\([0-9]\{1,\}\).*$|\1|p')
	minor=$(echo "${kernelver}" | sed -n 's|^[0-9]\{1,\}\.\([0-9]\{1,\}\).*$|\1|p')

	# now try to identify the patch level
	if [ $(grep -c "Linux version $major\.$minor\.[0-9]\{1,\}.*$" "${in}") -ne 0 ];
	then
		version=$(cat "${in}" | sed -n "s|^Linux version \($major\.$minor\.[0-9]\{1,\}\).*$|\1|p")
	else
		# wasn't able to detect the kernel version
		# exit with error
		echo "$(basename $0): can't detect the kernel version" >&2
		exit 1
	fi
elif [ "${what}" = "gcc" ];
then
	# get the content of the infile as version string
	versionstring=$(cat "${in}")

	# check if there is something like 'gcc... 123.456.789'
	# each version number may have 1 to 3 digits
	# and there have to be three numbers
	gcc=$(echo "${versionstring}" | \
		grep -c "(gcc (GCC) [[:digit:]]\{1,3\}\.[[:digit:]]\{1,3\}\.[[:digit:]]\{1,3\}")
	if [ $gcc -eq 0 ];
	then
		# no matching string found
		# exit with error
		echo "$(basename $0): can't detect the used gcc version" >&2
		exit 1
	fi

	# matching string found, extract version number
	version=$(echo "${versionstring}" | \
		sed -n 's|^.*(gcc (GCC) \([^ ]*\).*$|\1|g;p' | \
		sed -n '1p')

	# and check if the result is a valid version number
	good=$(echo "${version}" | grep -c '^[[:digit:]]\{1,3\}\.[[:digit:]]\{1,3\}\.[[:digit:]]\{1,3\}$')
	if [ "${good}" = "0" ];
	then
		echo "$(basename $0): '${version}' seems not to be a gcc version" >&2
		exit 1
	fi
else
	echo "$(basename $0): don't know how to extract '${what}'" >&2
	exit 1
fi

# print the version - only the first line
echo "${version}" | sed -n '1p'

exit 0
