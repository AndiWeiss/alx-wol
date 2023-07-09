#!/bin/sh

# get_source
# parameter:
# 1. kernel version (e.g. 6.0.3)
# 2. output folder
# 3. file name
# 4. path in kernel tree
get_source () {
	wget -nv -O $2/$3 https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/plain/$4/$3?h=$1
	if [ $? -ne 0 ];
	then
		exit 1
	fi
}

log_error() {
	echo "alx-wol: $*" 1>&2
	echo "alx-wol: $*" > /dev/kmsg
}

# initialize variable
srcversion=""
file2patch=""
current_module=""
insert=""

echo "${kernelver}" | grep "5\.1[5-9]\." > /dev/null
if [ $? -eq 0 ];
then
	# this is for kernel 5.19.x
	# these sources also match that kernel
	srcversion="v6.0.3"
	outdir="alx_5.19"
	files_to_fetch="alx.h ethtool.c hw.c hw.h main.c Makefile reg.h"
	patches="0000-alx-wol-v6.0.3.patch"
fi

if [ "${srcversion}" = "" ];
then
	echo "${kernelver}" | grep "6\.0\." > /dev/null
	if [ $? -eq 0 ];
	then
		# this is for kernel 6.0.x
		srcversion="v6.0.3"
		outdir="alx_6.0"
		files_to_fetch="alx.h ethtool.c hw.c hw.h main.c Makefile reg.h"
		patches="0000-alx-wol-v6.0.3.patch"
	fi
fi

if [ "${srcversion}" = "" ];
then
	echo "${kernelver}" | grep "6\.1\." > /dev/null
	if [ $? -eq 0 ];
	then
		# this is for kernel 6.1.x
		srcversion="v6.1.1"
		outdir="alx_6.1"
		files_to_fetch="alx.h ethtool.c hw.c hw.h main.c Makefile reg.h"
		# this patch also matches these sources
		patches="0000-alx-wol-v6.0.3.patch"
	fi
fi

if [ "${srcversion}" = "" ];
then
	echo "${kernelver}" | grep "6\.2\." > /dev/null
	if [ $? -eq 0 ];
	then
		# this is for kernel 6.2.x
		srcversion="v6.2.1"
		outdir="alx_6.2"
		files_to_fetch="alx.h ethtool.c hw.c hw.h main.c Makefile reg.h"
		# this patch also matches these sources
		patches="0000-alx-wol-v6.0.3.patch"
	fi
fi

if [ "${srcversion}" = "" ];
then
	echo "${kernelver}" | grep "6\.3\." > /dev/null
	if [ $? -eq 0 ];
	then
		# this is for kernel 6.3.x
		srcversion="v6.3.1"
		outdir="alx_6.3"
		files_to_fetch="alx.h ethtool.c hw.c hw.h main.c Makefile reg.h"
		patches="0001-alx-wol-v6.3.patch"
	fi
fi

if [ "${srcversion}" = "" ];
then
	echo "${kernelver}" | grep "6\.4\." > /dev/null
	if [ $? -eq 0 ];
	then
		# this is for kernel 6.4.x
		srcversion="v6.4.1"
		outdir="alx_6.4"
		files_to_fetch="alx.h ethtool.c hw.c hw.h main.c Makefile reg.h"
		patches="0001-alx-wol-v6.3.patch"
	fi
fi

if [ "${srcversion}" != "" ];
then
	# found a known kernel version
	# set working directory
	bdir="/usr/src/${module}-${module_version}"

	export $( grep -vE "^(#.*|\s*)$" ${bdir}/filelist )

	if [ ! -d "${bdir}/${outdir}" ];
	then
		# if the outdir doesn't exist the sources need to be fetched
		# first create the directory
		mkdir "${bdir}/${outdir}"

		# fetch the sources
		for file in ${files_to_fetch};
		do
			get_source ${srcversion} "${bdir}/${outdir}" ${file} ${original_path}
		done

		for patchfile in ${patches};
		do
			# apply all patches for these sources
			patch -d "${bdir}/${outdir}" -i "${bdir}/patches/${patchfile}" -p 2
			if [ $? != 0 ];
			then
				# exit in case of an error
				exit 1
			fi
		done

		# now search for MODULE_VERSION
		# search is done at the position
		# the files have been fetched to
		for file in ${files_to_fetch};
		do
			# check for source file
			echo "${file}" | grep '\.h$\|\.c$' > /dev/null
			if [ $? -eq 0 ];
			then
				# check each source file for MODULE_VERSION
				grep '^\W*MODULE_VERSION\W*(\W*\"[^"]*\"\W*)\W*;' ${bdir}/${outdir}/${file} > /dev/null
				if [ $? -eq 0 ];
				then
					# found line with MODULE_VERSION
					if [ "${file2patch}" = "" ];
					then
						# first file, remember it
						file2patch=${file}
					else
						# there's more than one.
						# don't know how to handle that ...
						log_error "multiple files containing MODULE_VERSION"
						file2patch="dont_patch"
					fi
				fi
			fi
		done

		if [ "${file2patch}" = "" ];
		then
			# if no file contains MODULE_VERSION
			# use main.c
			file2patch="main.c"
		fi

		if [ "${file2patch}" != "dont_patch" ];
		then
			# there is a file to do the version patch
			# save the original
			mv "${bdir}/${outdir}/${file2patch}" "${bdir}/${outdir}/${file2patch}${patchext}"
		fi

		# remember for next compilation
		echo "file2patch=${file2patch}" > ${bdir}/${outdir}/${versionpatch_file}
	else
		export $( grep -vE "^(#.*|\s*)$" ${bdir}/${outdir}/${versionpatch_file} )
	fi

	cp -r "${bdir}/${outdir}" "${PWD}"

	if [ "${file2patch}" != "dont_patch" ];
	then
		insert=$(date +%Y-%m-%d_%H:%M.%S)
		line=$(grep '^\W*MODULE_VERSION\W*(\W*\"[^"]*\"\W*)\W*;' ${outdir}/${file2patch}${patchext})
		if [ "${line}" = "" ];
		then
			# no version
			cp ${outdir}/${file2patch}${patchext} ${outdir}/${file2patch}
			echo >> ${outdir}/${file2patch}
			echo "MODULE_VERSION(\"${insert}\");" >> ${outdir}/${file2patch}
		else
			echo "${line}" | grep '[0-9]{4}-[0-9]{2}-[0-9]{2}_[0-9]{2}:[0-9]{2}.[0-9]{2}'> /dev/null
			if [ $? -eq 0 ];
			then
				# date and time already included
				# replace it
				cat ${outdir}/${file2patch}${patchext} | sed -n "s|^\(\W*MODULE_VERSION\W*(\)\(.*\)[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}_[0-9]\{2\}:[0-9]\{2\}.[0-9]\{2\}\(.*\)$|\1\2${insert}\3|g;p" > ${outdir}/${file2patch}
			else
				# date and time not yet included
				# add it in front of the original version string
				cat ${outdir}/${file2patch}${patchext} | sed -n "s|^\(\W*MODULE_VERSION\W*(\W*\"\)|\1${insert} |g;p" > ${outdir}/${file2patch}
			fi
		fi
	fi
	current_module=$(modinfo alx | sed -n 's|filename:\W*||p')
	echo "current_module=${current_module}" > ${bdir}/${module_file}
else
	log_error "This version doesn't support kernel ${kernelver}"
	exit 1
fi
