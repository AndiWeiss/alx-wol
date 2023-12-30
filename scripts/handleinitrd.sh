#!/bin/sh

i="$(grep '^[[:space:]]*BUILT_MODULE_NAME[[:space:]]*\[[0-9]\{1,\}\][[:space:]]*=' dkms.conf)"
all_names="$(echo "$i" | sed -n 's|^[^"]*"\([^"]*\).*$|\1|gp')"

i="$(grep '^[[:space:]]*DEST_MODULE_LOCATION[[:space:]]*\[0\][[:space:]]*=' dkms.conf)"
new_location="$(echo "$i" | sed -n 's|^[^=]*=[[:space:]]*\"\([^\"]*\).*$|\1|p')"

running="$(uname -r)"
if [ "${running}" = "${kernelver}" ] || [ "${kernelver}" = "" ];
then
	cur=0
	end=$(echo "$all_names" | wc -l)
	while [ $cur -lt $end ];
	do
		cur=$(expr $cur + 1)
		name="$(echo "$all_names" | sed -n "${cur}p")"
		if [ "${kernelver}" = "" ];
		then
			modules="$(find /lib/modules/$(uname -r)/ -type f -name "${name}".*)"
		else
			modules="$(find /lib/modules/${kernelver}/ -type f -name "${name}".*)"
		fi
		active=$(lsmod | grep -c "${name}")
		if [ $active -ne 0 ];
		then
			rmmod "$name"
			if [ "${kernelver}" = "" ];
			then
				module="$(echo "${modules}" | grep '/lib/modules/[^/]*/kernel/')"
			else
				module="$(echo "${modules}" | grep "/lib/modules/[^/]*${new_location}/")"
			fi
			insmod "${module}"
		fi
	done
fi

depmod

if [ "${kernelver}" = "" ];
then
	update-initramfs -u -k "${running}"
else
	update-initramfs -u -k "${kernelver}"
fi
