#!/bin/sh

# extract the kernel version out of the Debian kernel version
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
	# in debian systems kernelver contains the major and minor
	# version from kernel.org.
	# The patch level is not included.
	major=$(echo "${kernelver}" | sed -n 's|^\([0-9]\{1,\}\).*$|\1|p')
	minor=$(echo "${kernelver}" | sed -n 's|^[0-9]\{1,\}\.\([0-9]\{1,\}\).*$|\1|p')

	# now try to identify the patch level
	#if [ $(grep -c "Debian $major\.$minor\.[0-9]\{1,\}.*$" "${in}") -eq 0 ];
	if [ $(grep -c "$major\.$minor" "${in}") -ne 0 ];
	then
		version=$(cat "${in}" | sed -n "s|^.*version \($major\.$minor\.[0-9]\{1,\}\).*$|\1|p")
	else
		# wasn't able to detect the kernel creator
		# exit with error
		echo "$(basename $0): can't detect the kernel creator" >&2
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
		grep -c "([^(]*gcc[^()]*([^()]*) [[:digit:]]\{1,3\}\.[[:digit:]]\{1,3\}\.[[:digit:]]\{1,3\},")
	if [ $gcc -eq 0 ];
	then
		# no matching string found
		# exit with error
		echo "can't detect the used gcc version"
		exit 1
	fi

	# matching string found, extract version number
	version=$(echo "${versionstring}" | \
		grep "([^(]*gcc[^()]*([^()]*) [[:digit:]]\{1,3\}\.[[:digit:]]\{1,3\}\.[[:digit:]]\{1,3\}," | \
		sed -n '1p' | \
		sed -n 's|^.*([^(]*gcc[^()]*([^()]*) \([[:digit:]]\{1,3\}\.[[:digit:]]\{1,3\}\.[[:digit:]]\{1,3\}\),.*$|\1|p')

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
