#!/bin/sh

# first parameter: kernel file
# second parameter: path to matching kernel headers
# third parameter: path to temp dir

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

ubuntu=$(echo "${versionstring}" | grep -c ' (Ubuntu [^ )]* [[:digit:]]\{1,3\}\.[[:digit:]]\{1,3\}\.[[:digit:]]\{1,3\})$')
if [ ${ubuntu} -gt 0 ];
then
	echo "ubuntu kernel"
	version="v$(echo "${versionstring}" | sed -n '1p' | sed -n "s|^.* (Ubuntu [^ )]* \([^)]*\))$|\1|p")"
else
	echo "vanilla kernel"
	version="v$(echo "${versionstring}" | sed -n '1p' | sed -n "s|^Linux version \([[:digit:]]\{1,3\}\.[[:digit:]]\{1,3\}\.[[:digit:]]\{1,3\}\).*$|\1|p")"
fi
echo "version: >${version}<"
