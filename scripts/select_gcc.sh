#!/bin/sh

# first parameter: architecture (e.g. x86_64)
# second parameter: temp folder
# third parameter: requested version
# fourth parameter (optional): file containing additional compilers

if [ $# -lt 3 ];
then
	echo "$(basename $0 requires at least 3 parameters)"
	exit 1
fi
	
arch="$1"
temp="$2"
req="$3"

list="${temp}/available_gcc"

mkdir -p "${temp}"
truncate -s 0 "${list}.unsort"

get_version ()
{
	echo "$1" | sed -n 's|^.* \([[:digit:]]\{1,\}\.[[:digit:]]\{1,\}\.[[:digit:]]\{1,\}\)$|\1|p'
}

for exe in $(ls /usr/bin/${arch}*gcc*)
do
	if [ -f "${exe}" ] && [ ! -L "${exe}" ] && [ -x "${exe}" ];
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

if [ $# -gt 3 ] && [ -f "$4" ];
then
	for exe in $(cat "$4")
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

cp "${list}.unsort" /
sort -n "${list}.unsort" > "${list}"
rm "${list}.unsort"

i=$(echo "${req}" | grep -c '^[[:digit:]]\{1,\}\.[[:digit:]]\{1,\}\.[[:digit:]]\{1,\}$')
if [ $i -eq 0 ];
then
	echo "requested version has to be number.number.number"
	exit 1
fi

req_major=$(echo "${req}" | sed -n 's|^\([[:digit:]]\{1,\}\)\.[[:digit:]]\{1,\}\.[[:digit:]]\{1,\}$|\1|p')
req_minor=$(echo "${req}" | sed -n 's|^[[:digit:]]\{1,\}\.\([[:digit:]]\{1,\}\)\.[[:digit:]]\{1,\}$|\1|p')
req_patch=$(echo "${req}" | sed -n 's|^[[:digit:]]\{1,\}\.[[:digit:]]\{1,\}\.\([[:digit:]]\{1,\}\)$|\1|p')

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

echo "${use}"
