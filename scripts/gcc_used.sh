#!/bin/sh

# detect the gcc version used by analysing the version string
# of the kernel

# first parameter: file containing kernel version string
# second parameter: where to put the gcc version

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
		echo "can't access $in"
		exit 1
	fi

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
	if [ $good -ne 1 ];
	then
		# it's not, exit with error
		echo "can't detect the used gcc version"
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
			echo "wasn't able to create $(dirname "${out}")"
			exit 1
		fi
	fi

	# write the gcc version into the outfile
	echo "${version}" > ${out}
	if [ $? -ne 0 ];
	then
		# error on file creation
		# exit with error
		echo "wasn't able to create §{out}"
		exit 1
	fi
fi
