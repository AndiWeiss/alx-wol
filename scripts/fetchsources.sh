#!/bin/sh

log_it()
{
	echo "$*"
}

fetch_sources="$(dirname "$0")/fetch_kernelparts.sh"
patch_sources="$(dirname "$0")/patch_sources.sh"

file_list="${PWD}/.fetched_files"

kernel_version=$(cat "${PWD}/${kernelver}/kernel_version")

truncate -s 0 "${file_list}"

"${fetch_sources}" "v${kernel_version}" "${PWD}/sources.txt" "${PWD}" "${file_list}"
if [ $? -ne 0 ];
then
	log_it "$(basename "${fetch_sources}") failed"
	exit 1
fi

"${patch_sources}" "${PWD}" "${PWD}/sources.txt" "${file_list}"
if [ $? -ne 0 ];
then
	log_it "$(basename "${patch_sources}") failed"
	exit 1
fi
