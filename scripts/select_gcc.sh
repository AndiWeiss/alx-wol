#!/bin/sh

# first parameter: architecture (e.g. x86_64)
# second parameter: temp folder
# third parameter: compiler type
# fourth parameter: requested version

if [ $# -lt 3 ];
then
	echo "$(basename $0) requires at least 3 parameters" >&2
	exit 1
fi

arch="$1"
temp="$2"
type="$3"
req="$4"

list="${temp}/available_versions"

# create file for available compiler list
mkdir -p "${temp}"
truncate -s 0 "${list}.unsort"

get_version ()
{
	# extract the version information out of "$type --version"
	# take the three digit version at the end of the line
	echo "$1" | sed -n 's|^.* \([[:digit:]]\{1,\}\.[[:digit:]]\{1,\}\.[[:digit:]]\{1,\}\).*$|\1|p'
}

# check for available compilers of the given type
# first try: ${arch}*${type}*
compiler=$(find /usr/bin/ -mindepth 1 -maxdepth 1 -name "${arch}*${type}*" -type f -executable)
if [ "${compiler}" = "" ]; then
	# nothing found, not try without architecture
	compiler=$(find /usr/bin/ -mindepth 1 -maxdepth 1 -name "*${type}*" -type f -executable)
fi
if [ "${compiler}" = "" ]; then
	# still nothing found, print errorlog
	echo "no compiler of type ${type} found!" >&2
	exit 1;
fi
# filter only those matching "*${type}$"
compiler_tmp=$(echo "${compiler}" | grep "${type}$")
# add those matching "*{type}-<at least one digit>"
compiler_tmp="${compiler_tmp} $(echo "${compiler}" | grep "${type}-[0-9]\+")"
if [ "${compiler_tmp}" != "" ]; then
	# if there is either "*${type}$" or "*${type}-<at least one digit>"
	# limit the try to these executables
	compiler="${compiler_tmp}"
fi
for exe in ${compiler}; do
	# use first line of output as version string
	versionstring=$(${exe} --version | head -n 1)
	# check if it is the requested type
	if [ $(echo "${versionstring}" | grep -c "^${type}\s") -eq 1 ]; then
		# yes
		version="$(get_version "${versionstring}" | sed -n 's|\.| |gp')"
		# write the version in a temp file
		echo "$version ${exe}" >> "${list}.unsort"
	fi
done

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
