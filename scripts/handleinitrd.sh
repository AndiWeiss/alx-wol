#!/bin/sh

# $1: kernel version to handle
# $2: install or remove
kernelver="$1"
what="$2"

i="$(grep '^[[:space:]]*BUILT_MODULE_NAME[[:space:]]*\[[0-9]\{1,\}\][[:space:]]*=' dkms.conf)"
all_names="$(echo "$i" | sed -n 's|^[^"]*"\([^"]*\).*$|\1|gp')"

i="$(grep '^[[:space:]]*DEST_MODULE_LOCATION[[:space:]]*\[0\][[:space:]]*=' dkms.conf)"
new_location="$(echo "$i" | sed -n 's|^[^=]*=[[:space:]]*\"\([^\"]*\).*$|\1|p')"

running="$(uname -r)"
if [ "${running}" = "${kernelver}" ];
then
	cur=0
	end=$(echo "$all_names" | wc -l)
	while [ $cur -lt $end ];
	do
		cur=$(expr $cur + 1)
		name="$(echo "$all_names" | sed -n "${cur}p")"
		modules="$(find /lib/modules/${kernelver}/ -type f -name "${name}".*)"
		active=$(lsmod | grep -c "${name}")
		if [ $active -ne 0 ];
		then
			rmmod "$name"
			if [ "${what}" = "install" ];
			then
				module="$(echo "${modules}" | grep "/lib/modules/[^/]*${new_location}/")"
			else
				module="$(echo "${modules}" | grep '/lib/modules/[^/]*/kernel/')"
			fi
			insmod "${module}"
		fi
	done
fi

depmod "${kernelver}"

update-initramfs -u -k "${kernelver}"
