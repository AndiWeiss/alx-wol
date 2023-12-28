#!/bin/sh

# parameter:
# $1: kernel version (e.g. 6.5.13)
# $2: file containing the files to fetch
# $3: directory where to put them
# $4: file to list all fetched files

kernver="$1"
export kernver
config="$2"
writeto="$3"
got_files="$4"

patchext=".before_patch"

exit_on_error ()
{
	while read line;
	do
		if [ -f "${line}" ];
		then
			rm "${line}"
		fi
	done < "${got_files}"

	exit 1
}

version_patch ()
{
	file2patch="$1"

	insert=$(date +%Y-%m-%d_%H:%M.%S)

	line=$(grep '^[[:space:]]*MODULE_VERSION[[:space:]]*([^)]*)' ${file2patch})
	if [ "${line}" = "" ];
	then
		# no version
		echo >> "${file2patch}"
		echo "MODULE_VERSION(\"${insert}\");" >> "${file2patch}"
	else
		mv "${file2patch}" "${file2patch}${patchext}"
		i="$(echo "${line}" | grep -c '^[[:space:]]*MODULE_VERSION[[:space:]]*([^)]*[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}_[0-9]\{2\}:[0-9]\{2\}.[0-9]\{2\}')"
		if [ $i -ne 0 ];
		then
			# date and time already included
			# replace it
			cat "${file2patch}${patchext}" | sed -n "s|^\([[:space:]]*MODULE_VERSION[[:space:]]*([^)]*\)[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}_[0-9]\{2\}:[0-9]\{2\}.[0-9]\{2\}\(.*\)$|\1${insert}\2|g;p"
		else
			# date and time not yet included
			# add it behind the original version string
			cat "${file2patch}${patchext}" | sed -n "s|^\([[:space:]]*MODULE_VERSION[[:space:]]*([^)]*\)\().*\)$|\1 \"${insert}\"\2|g;p"
		fi
		rm "${file2patch}${patchext}"
	fi
}

read_tag="$(dirname "$0")/read_tag.sh"

all_patches="$("${read_tag}" "${kernver}" patches 0 "${config}")"
end=$(echo "${all_patches}" | wc -l)
cur=0

while [ $cur -lt $end ];
do
	cur=$(expr $cur + 1)
	line="$(echo "${all_patches}" | sed -n "${cur}p")"
	file="$(realpath -s "${line}")"
	if [ ! -f "${file}" ];
	then
		echo "$(basename "$0"): file $file doesn't exist"
		exit_on_error
	fi

	patch -d "${writeto}" -p 1 < "${file}"
	if [ $? -ne 0 ];
	then
		while read line;
		do
			if [ -f "${line}" ];
			then
				rm "${line}"
			fi
		done < "${got_files}"
		echo "$(basename "$0"): patch $file doesn't apply"
		exit_on_error
	fi
done

all_versionfiles="$("${read_tag}" "${kernver}" versionpatch 0 "${config}")"
end=$(echo "${all_versionfiles}" | wc -l)
cur=0

while [ $cur -lt $end ];
do
	cur=$(expr $cur + 1)
	line="$(echo "${all_versionfiles}" | sed -n "${cur}p")"
	file="$(realpath -s "${line}")"
	if [ ! -f "${file}" ];
	then
		echo "$(basename "$0"): file $file doesn't exist"
		exit_on_error
	fi

	version_patch "${file}"

	if [ $? -ne 0 ];
	then
		echo "$(basename "$0"): patch $file doesn't apply"
		exit_on_error
	fi
done
