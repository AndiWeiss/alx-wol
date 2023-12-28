#!/bin/sh

file="$1"
store="$2"
got_files="$3"

dir=$(dirname "${store}")
if [ ! -d "${dir}" ];
then
	mkdir -p "${dir}"
	if [ $? -ne 0 ];
	then
		exit 1
	fi
fi

if [ -d "${store}" ];
then
	rm -rf "${store}"
fi

wget -nv -O "${store}" https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/plain/${file}?h=v${kernver}
if [ $? -ne 0 ];
then
	rm "${store}"
	exit 1
fi

echo "${file}" | sed -n "s|^${kerneldir}/||p" >> "${got_files}"

exit 0
