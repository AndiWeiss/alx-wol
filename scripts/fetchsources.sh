#!/bin/sh

# fetch and patch the sources defined in sources.txt
#
# script expects one parameter: directory where sources are installed

install_tree="$1"

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
# use the Makefile for that
mf="$install_tree/$kernelver/build/Makefile"
# check if this is the 'final' kernel Makefile
if [ $(grep -c '^\s*VERSION\s*=' $mf) -eq 0 ]; then
	# NO!
	# check if this Makefile includes another one
	if [ $(grep -c '^\s*include\s\+' $mf) -ne 1 ]; then
		# NO!
		# --> can't continue work
		echo "can't find makefile containing the kernel version" 1>&2
		exit 1
	fi
	# get the line 'include ...'
	mf="$(grep '^\s*include\s\+' $mf)"
	# remove the 'include ' from this line
	mf="$(echo "$mf" | sed -n 's|^\s*include\s\+||g;p')"
	# check if the path is absolute
	if [ $(echo "$mf" | grep -c '^/') -ne 1 ]; then
		# NO!
		# create the absolute path from relative path
		mf="$install_tree/$kernelver/build/$mf"
	fi
	# check if the file exists
	if [ ! -f "$mf" ]; then
		# NO
		# --> can't continue work
		echo "strange Makefile, can't work" 1>&2
		exit 1
	fi
fi

# get the kernel version information out of the Makefile
version=$(grep '^\s*VERSION\s*=' $mf | sed -n 's|^.*[= ]\(\S\+\)$|\1|g;p')
patchlevel=$(grep '^\s*PATCHLEVEL\s*=' $mf | sed -n 's|^.*[= ]\(\S\+\)$|\1|g;p')
sublevel=$(grep '^\s*SUBLEVEL\s*=' $mf | sed -n 's|^.*[= ]\(\S\+\)$|\1|g;p')
if [ "$version" = "" ] || [ "$patchlevel" = "" ] || [ "$sublevel" = "" ]; then
	echo "can't detect kernel version information, can't work" 1>&2
	exit 1
fi
kernel_version=$version.$patchlevel.$sublevel

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
