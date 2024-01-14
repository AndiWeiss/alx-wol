#!/bin/bash

# first parameter: path in kernel source
# second parameter: file containing the directory content
# third parameter: list files here

src="$1"
list="$2"
got_files="$3"

if [ ! -f "${list}" ];
then
	echo "file ${list} doesn't exist"
	exit 1
fi

mv "${list}" "${list}.handle_this"
if [ $? -ne 0 ];
then
	exit 1
fi

mkdir "${list}"
if [ $? -ne 0 ];
then
	exit 1
fi

ldv="v$(echo ${kernver} | sed -n 's|^\([0-9]\{1,\}\.[0-9]\{1,\}\)\.0$|\1|;p')"

while read line
do
	i=$(echo "${line}" | grep -c "/${src}/.*?h=${ldv}'")
	if [ ${i} -ne 0 ];
	then
		i=$(echo "${line}" | grep -c "/${src}/.*/?h=${ldv}'")
		if [ ${i} -ne 0 ];
		then
			# directory
			file=$(echo "${line}" | sed -n "s|^.*/\(${src}/.*\)/?h=${ldv}.*$|\1|p")
			#echo "directory: >${file}<"
		else
			#file
			file=$(echo "${line}" | sed -n "s|^.*/\(${src}/.*\)?h=${ldv}.*$|\1|p")
			#echo "file:      >${file}<"
		fi
		wget -nv -O ${list}/$(basename ${file}) https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/plain/${file}?h=${ldv}
		if [ $? -ne 0 ];
		then
			exit 1
		fi
		if [ ${i} -ne 0 ];
		then
			"${fetch_dir}" "${file}" "${list}/$(basename ${file})" "${got_files}"
		else
			echo "${file}" | sed -n "s|^${kerneldir}/||p" >> "${got_files}"
		fi
	fi
done < "${list}.handle_this"

rm "${list}.handle_this"
