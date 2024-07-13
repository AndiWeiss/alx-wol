#!/bin/sh

# detect the gcc version used by analysing the version string
# of the kernel

# first parameter: file containing kernel version string
# second parameter: where to put the gcc version

scriptpath="$(dirname $0)"
in="$1"
out="$2"

# check if the out file already exists
# if yes: don't do anything
if [ ! -f "${out}" ];
then
	# outfile doesn't exist
	# start analysis

	# check if there is an infile
	if [ ! -f "${in}" ];
	then
		# no, exit with error
		echo "$(basename $0): can't access $in" >&2
		exit 1
	fi

	# now try to identify the kernel provider
	if [ $(grep -c "Ubuntu" "${in}") -ne 0 ];
	then
		# ubuntu kernel
		version=$(${scriptpath}/Ubuntu.sh "${in}" "gcc")
	elif [ $(grep -c "Debian" "${in}") -ne 0 ];
	then
		# Debian kernel
		version=$(${scriptpath}/Debian.sh "${in}" "gcc")
	elif [ $(grep -c "archlinux" "${in}") -ne 0 ];
	then
		version=$(${scriptpath}/Archlinux.sh "${in}" "gcc")
	else
		# wasn't able to detect the kernel creator
		# exit with error
		echo "$(basename $0): can't detect the kernel creator" >&2
		exit 1
	fi

	if [ $? -ne 0 ];
	then
		echo "$(basename $0): wasn't able to get gcc version used" >&2
		exit 1
	fi

	# is the directory for the outfile available?
	if [ ! -d "$(dirname "${out}")" ];
	then
		# no, create it
		mkdir -p "$(dirname "${out}")"
		if [ $? -ne 0 ];
		then
			# problem on creating the directory
			# exit with error
			echo "$(basename $0): wasn't able to create $(dirname "${out}")" >&2
			exit 1
		fi
	fi

	# write the gcc version into the outfile
	echo "${version}" > ${out}
	if [ $? -ne 0 ];
	then
		# error on file creation
		# exit with error
		echo "$(basename $0): wasn't able to create §{out}" >&2
		exit 1
	fi

	echo "#### kernel was compiled with gcc ${version} ####" >&2
fi
