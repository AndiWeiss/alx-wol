#!/bin/bash

# first parameter: path in kernel source
# second parameter: file containing the directory content

src="$1"
list="$2"

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

while read line
do
	i=$(echo "${line}" | grep -c "/${src}/.*?h=${kernver}'")
	if [ ${i} -ne 0 ];
	then
		i=$(echo "${line}" | grep -c "/${src}/.*/?h=${kernver}'")
		if [ ${i} -ne 0 ];
		then
			# directory
			file=$(echo "${line}" | sed -n "s|^.*/\(${src}/.*\)/?h=${kernver}.*$|\1|p")
			#echo "directory: >${file}<"
		else
			#file
			file=$(echo "${line}" | sed -n "s|^.*/\(${src}/.*\)?h=${kernver}.*$|\1|p")
			#echo "file:      >${file}<"
		fi
		wget -nv -O ${list}/$(basename ${file}) https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/plain/${file}?h=${kernver}
		if [ ${i} -ne 0 ];
		then
			${fetch_dir} ${file} ${list}/$(basename ${file})
		fi
	fi
done < "${list}.handle_this"

rm "${list}.handle_this"
