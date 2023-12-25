#!/bin/sh

# first parameter: kernel file
# second parameter: path to matching kernel headers
# third parameter: path to temp dir

if [ $# -eq 3 ];
then
	kernel="$1"
	headers="$2"
	temp="$3"

	"${headers}/scripts/extract-vmlinux" "${kernel}" > "${temp}/vmlinux"
	if [ $? -ne 0 ];
	then
		echo "${kernel} seems not to be a vmlinuz file"
		exit 1
	fi

	vmlinux="${temp}/vmlinux"

	versionstring=$(strings ${vmlinux} | grep '^Linux version ')
	if [ "${versionstring}" = "" ];
	then
		echo "this seems not to be a linux kernel"
		exit 1
	fi
elif [ $# -eq 1 ];
then
	if [ ! -f "$1" ];
	then
		echo "can't access $1"
		exit 1
	fi
	versionstring=$(cat "$1")
else
	echo "script requires ..."
	echo "either one parameter containing a file with the kernel version string in"
	echo "or three parameters:"
	echo "	kernel file"
	echo "	path to matching kernel headers"
	echo "	path to temp directory"
	exit 1
fi

gcc=$(echo "${versionstring}" | \
	grep -c "([^(]*gcc[^()]*([^()]*) [[:digit:]]\{1,3\}\.[[:digit:]]\{1,3\}\.[[:digit:]]\{1,3\},")
if [ $gcc -eq 0 ];
then
	echo "can't detect the used gcc version"
	exit 1
fi

version=$(echo "${versionstring}" | \
	grep "([^(]*gcc[^()]*([^()]*) [[:digit:]]\{1,3\}\.[[:digit:]]\{1,3\}\.[[:digit:]]\{1,3\}," | \
	sed -n '1p' | \
	sed -n 's|^.*([^(]*gcc[^()]*([^()]*) \([[:digit:]]\{1,3\}\.[[:digit:]]\{1,3\}\.[[:digit:]]\{1,3\}\),.*$|\1|p')

good=$(echo "${version}" | grep -c '^[[:digit:]]\{1,3\}\.[[:digit:]]\{1,3\}\.[[:digit:]]\{1,3\}$')
if [ $good -ne 1 ];
then
	echo "can't detect the used gcc version"
	exit 1
fi

echo "${version}"
exit 0	
