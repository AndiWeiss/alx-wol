#!/bin/sh

# first parameter: architecture (e.g. x86_64)
# second parameter: temp folder
# third parameter: requested version
# fourth parameter (optional): file containing additional compilers

if [ $# -lt 3 ];
then
	echo "$(basename $0) requires at least 3 parameters" >&2
	exit 1
fi

arch="$1"
temp="$2"
req="$3"
add="$4"

list="${temp}/available_gcc"

# create file for available compiler list
mkdir -p "${temp}"
truncate -s 0 "${list}.unsort"

get_version ()
{
	# extract the version information out of 'gcc --version'
	# take the three digit version at the end of the line
	echo "$1" | sed -n 's|^.* \([[:digit:]]\{1,\}\.[[:digit:]]\{1,\}\.[[:digit:]]\{1,\}\).*$|\1|p'
}

# ask all files which may be a gcc for the version
# first try with architecture in the name
gccs="$(ls /usr/bin/${arch}*gcc* 2>&1)"
if [ $? -ne 0 ]; then
	# nothing found, now try without architecture
	gccs="$(ls /usr/bin/*gcc* 2>&1)"
fi
for exe in $gccs;
do
	# check for: file, no link, executable
	if [ -f "${exe}" ] && [ ! -L "${exe}" ] && [ -x "${exe}" ];
	then
		# ask for version
		versionstring="$(${exe} --version | \
			grep 'gcc.*[[:digit:]]\{1,3\}\.[[:digit:]]\{1,3\}\.[[:digit:]]\{1,3\}.*$')"
		# and extract it if requirements are fulfilled
		if [ "${versionstring}" != "" ];
		then
			version="$(get_version "${versionstring}" | sed -n 's|\.| |gp')"
			# write the version in a temp file
			echo "$version ${exe}" >> "${list}.unsort"
		fi
	fi
done

# do the same for the compiler mentioned in the given file
if [ $# -gt 3 ] && [ -f "${add}" ];
then
	for exe in $(cat "${add}")
	do
		if [ -f "${exe}" ] && [ -x "${exe}" ];
		then
			versionstring="$(${exe} --version | \
				grep 'gcc.*[[:digit:]]\{1,3\}\.[[:digit:]]\{1,3\}\.[[:digit:]]\{1,3\}$')"
			if [ "${versionstring}" != "" ];
			then
				version="$(get_version "${versionstring}" | sed -n 's|\.| |gp')"
				echo "$version ${exe}" >> "${list}.unsort"
			fi
		fi
	done
fi

# sort the list of compilers
sort -n "${list}.unsort" > "${list}"
rm "${list}.unsort"

# check if version request is valid
i=$(echo "${req}" | grep -c '^[[:digit:]]\{1,\}\.[[:digit:]]\{1,\}\.[[:digit:]]\{1,\}$')
if [ $i -eq 0 ];
then
	echo "$(basename $0): requested version has to be number.number.number" >&2
	exit 1
fi

# get requested version as single numbers
req_major=$(echo "${req}" | sed -n 's|^\([[:digit:]]\{1,\}\)\.[[:digit:]]\{1,\}\.[[:digit:]]\{1,\}$|\1|p')
req_minor=$(echo "${req}" | sed -n 's|^[[:digit:]]\{1,\}\.\([[:digit:]]\{1,\}\)\.[[:digit:]]\{1,\}$|\1|p')
req_patch=$(echo "${req}" | sed -n 's|^[[:digit:]]\{1,\}\.[[:digit:]]\{1,\}\.\([[:digit:]]\{1,\}\)$|\1|p')

# and search the best matching executable
use=""
while read line;
do
	found_major=$(echo "${line}" | sed -n 's|^\([[:digit:]]\{1,\}\) .*|\1|p')
	found_minor=$(echo "${line}" | sed -n 's|^[[:digit:]]\{1,\} \([[:digit:]]\{1,\}\) .*|\1|p')
	found_patch=$(echo "${line}" | sed -n 's|^[[:digit:]]\{1,\} [[:digit:]]\{1,\} \([[:digit:]]\{1,\}\) .*|\1|p')
	use=$(echo "${line}" | sed -n 's|^[[:digit:]]\{1,\} [[:digit:]]\{1,\} [[:digit:]]\{1,\} ||p')
	if [ $found_major -eq $req_major ];
	then
		if [ $found_minor -eq $req_minor ];
		then
			if [ $found_patch -eq $req_patch ];
			then
				break
			elif [ $found_patch -gt $req_patch ];
			then
				break
			fi
		elif [ $found_minor -gt $req_minor ];
		then
			break
		fi
	elif [ $found_major -gt $req_major ];
	then
		break
	fi
done < "${list}"

rm "${list}"

echo "#### using ${use} to compile module ####" >&2
echo "${use}"
