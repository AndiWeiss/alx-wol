#!/bin/sh

log_it()
{
	echo "$*" >> /log.txt
}

temp=$(realpath "../temp")

log_it "----------------------------------"
log_it "PWD:		$PWD"
log_it "module:		$module"
log_it "arch:		$arch"
log_it "module_version:	$module_version"
log_it "kernelver:	$kernelver"
log_it "	-------"
log_it "temp:		$temp"

extract_kversion="$(dirname "$0")/extract_kversion.sh"
detect_kversion="$(dirname "$0")/detect_kernelversion.sh"
fetch_sources="$(dirname "$0")/fetch_kernelparts.sh"

headers="/usr/src/linux-headers-${kernelver}"
kernel="/boot/vmlinuz-${kernelver}"

#"${extract_kversion}" "${kernel}" "${headers}" "${temp}" "${temp}/kernel_version"
#if [ $? -ne 0 ];
#then
#	log_it "extract_kversion failed"
#	exit 1
#fi

version=$("${detect_kversion}" "${temp}/kernel_version")
if [ $? -ne 0 ];
then
	log_it "detect_kversion failed"
	exit 1
fi

"${fetch_sources}" "v${version}" "${PWD}/sources.txt" "${PWD}"
if [ $? -ne 0 ];
then
	log_it "fetch_sources failed"
	exit 1
fi
