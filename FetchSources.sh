#!/bin/sh

# get_source
# parameter:
# 1. kernel version (e.g. 6.0.3)
# 2. output folder
# 3. file name
get_source () {
	wget -O $2/$3 https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/plain/drivers/net/ethernet/atheros/alx/$3?h=$1
	if [ $? -ne 0 ];
	then
		exit 1
	fi
}

srcversion=""

echo "${kernelver}" | grep "5\.1[5-9]\." > /dev/null
if [ $? -eq 0 ];
then
	srcversion="v6.0.3"
	outdir="alx_5.19"
	patches="0000-alx-wol-v6.0.3.patch"
fi

if [ "${srcversion}" = "" ];
then
	echo "${kernelver}" | grep "6\.0\." > /dev/null
	if [ $? -eq 0 ];
	then
		srcversion="v6.0.3"
		outdir="alx_6.0"
		patches="0000-alx-wol-v6.0.3.patch"
	fi
fi

if [ "${srcversion}" = "" ];
then
	echo "${kernelver}" | grep "6\.1\." > /dev/null
	if [ $? -eq 0 ];
	then
		srcversion="v6.1.1"
		outdir="alx_6.1"
		patches="0000-alx-wol-v6.0.3.patch"
	fi
fi

if [ "${srcversion}" = "" ];
then
	echo "${kernelver}" | grep "6\.2\." > /dev/null
	if [ $? -eq 0 ];
	then
		srcversion="v6.2.1"
		outdir="alx_6.2"
		patches="0000-alx-wol-v6.0.3.patch"
	fi
fi

if [ "${srcversion}" != "" ];
then
	bdir="/usr/src/${module}-${module_version}"
	if [ ! -d "${bdir}/${outdir}" ];
	then
		mkdir "${bdir}/${outdir}"
		get_source ${srcversion} "${bdir}/${outdir}" alx.h
		get_source ${srcversion} "${bdir}/${outdir}" ethtool.c
		get_source ${srcversion} "${bdir}/${outdir}" hw.c
		get_source ${srcversion} "${bdir}/${outdir}" hw.h
		get_source ${srcversion} "${bdir}/${outdir}" main.c
		get_source ${srcversion} "${bdir}/${outdir}" Makefile
		get_source ${srcversion} "${bdir}/${outdir}" reg.h
		for patch in ${patches};
		do
			patch -d "${bdir}/${outdir}" -i "${bdir}/patches/${patch}" -p 2
		done
		cp -pr "${bdir}/${outdir}" .
	fi
fi
