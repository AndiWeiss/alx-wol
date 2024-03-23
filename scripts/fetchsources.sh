#!/bin/sh

# fetch and patch the sources defined in sources.txt
#
# script expects no parameter

log_it()
{
	echo "$*"
}

# script for fetching the sources
fetch_sources="$(dirname "$0")/fetch_kernelparts.sh"
# script for patching the sources
patch_sources="$(dirname "$0")/patch_sources.sh"

# file to store the fetched files
file_list="${PWD}/.fetched_files"

# get the kernel version
kernel_version=$(cat "${PWD}/../${kernelver}/kernel_version")

# empty the file for logging the fetched files
truncate -s 0 "${file_list}"

# fetch the sources
"${fetch_sources}" "${kernel_version}" "${PWD}/sources.txt" "${PWD}" "${file_list}"
if [ $? -ne 0 ];
then
	# in case of error exit
	log_it "$(basename "${fetch_sources}") failed"
	exit 1
fi

# patch the sources
"${patch_sources}" "${kernel_version}" "${PWD}/sources.txt" "${PWD}" "${file_list}"
if [ $? -ne 0 ];
then
	# in case of error exit
	log_it "$(basename "${patch_sources}") failed"
	exit 1
fi
