#!/bin/sh

# first parameter: file containing kernel version string
# second parameter: where to put the gcc version

in="$1"
out="$2"

if [ ! -f "${out}" ];
then
	if [ ! -f "${in}" ];
	then
		echo "can't access $in"
		exit 1
	fi
	versionstring=$(cat "${in}")

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

	if [ ! -d "$(dirname "${out}")" ];
	then
		mkdir -p "$(dirname "${out}")"
		if [ $? -ne 0 ];
		then
			echo "wasn't able to create $(dirname "${out}")"
			exit 1
		fi
	fi

	echo "${version}" > ${out}
	if [ $? -ne 0 ];
	then
		echo "wasn't able to create §{out}"
		exit 1
	fi
fi
