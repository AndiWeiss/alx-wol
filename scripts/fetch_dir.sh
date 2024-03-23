#!/bin/bash

# fetch a complete directory from kernel.org
# the file containing the directory content has been fetched
# from kernel.org

# first parameter: path in kernel source
# second parameter: file containing the directory content
# third parameter: list files here
# additional environment:
# kernver has to contain the required kernel version
# in format 'x.y' or 'x.y.z'
src="$1"
list="$2"
got_files="$3"

# check if the content file is available
if [ ! -f "${list}" ];
then
	# no, exit with error
	echo "file ${list} doesn't exist"
	exit 1
fi

# save the content file
mv "${list}" "${list}.handle_this"
if [ $? -ne 0 ];
then
	# move failed, exit with error
	exit 1
fi

# create the required directory
mkdir "${list}"
if [ $? -ne 0 ];
then
	# directory creation failed, exit with error
	exit 1
fi

# create the kernel version string required for fetching the sources
ldv="v$(echo ${kernver} | sed -n 's|^\([0-9]\{1,\}\.[0-9]\{1,\}\)\.0$|\1|;p')"

# loop through the content file
while read line
do
	# check if it contains a http link to a file
	i=$(echo "${line}" | grep -c "/${src}/.*?h=${ldv}'")
	if [ ${i} -ne 0 ];
	then
		# it does
		# check if it is points to a directory
		i=$(echo "${line}" | grep -c "/${src}/.*/?h=${ldv}'")
		if [ ${i} -ne 0 ];
		then
			# directory
			file=$(echo "${line}" | sed -n "s|^.*/\(${src}/.*\)/?h=${ldv}.*$|\1|p")
		else
			#file
			file=$(echo "${line}" | sed -n "s|^.*/\(${src}/.*\)?h=${ldv}.*$|\1|p")
		fi
		# fetching is the same for file or directory
		# if it is a directory there's also a file
		# containing the html description of the directory content
		wget -nv -O ${list}/$(basename ${file}) https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/plain/${file}?h=${ldv}
		if [ $? -ne 0 ];
		then
			# fetch failed, exit with error
			exit 1
		fi

		# check if it is a file or a directory
		if [ ${i} -ne 0 ];
		then
			# it's a directory, fetch it
			"${fetch_dir}" "${file}" "${list}/$(basename ${file})" "${got_files}"
		else
			# it's a file, log it
			echo "${file}" | sed -n "s|^${kerneldir}/||p" >> "${got_files}"
		fi
	fi
done < "${list}.handle_this"

# remove the directory content file
rm "${list}.handle_this"
