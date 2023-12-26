#!/bin/sh

# first parameter: kernel file
# second parameter: path to matching kernel headers
# third parameter: path to temp dir
# fourth parameter: file to create

kernel="$1"
headers="$2"
temp="$3"
versionfile="$4"

if [ ! -d "${temp}" ];
then
	mkdir -p "${temp}"
	if [ $? -ne 0 ];
	then
		echo "wasn't able to create ${temp}"
		exit 1
	fi
fi

if [ ! -f "${versionfile}" ];
then
	"${headers}/scripts/extract-vmlinux" "${kernel}" > "${temp}/vmlinux"
	if [ $? -ne 0 ];
	then
		echo "${kernel} seems not to be a vmlinuz file"
		exit 1
	fi

	vmlinux="${temp}/vmlinux"

	strings "${vmlinux}" | grep '^Linux version ' > "${versionfile}"

	i=$(grep -c '^Linux version ' "${versionfile}")
	if [ $i -eq 0 ];
	then
		echo "${vmlinux} seems not to be a vmlinux file"
		rm "${versionfile}"
		exit 1
	fi

	rm "${temp}/vmlinux"
fi
