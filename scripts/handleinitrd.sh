#!/bin/sh

# this script handles the initrd creation

# $1: kernel version to handle
# $2: install or remove
kernelver="$1"
what="$2"

# get the name of the module out of the dkms.conf file
i="$(grep '^[[:space:]]*BUILT_MODULE_NAME[[:space:]]*\[[0-9]\{1,\}\][[:space:]]*=' dkms.conf)"
# maybe there is more than one ...
all_names="$(echo "$i" | sed -n 's|^[^"]*"\([^"]*\).*$|\1|gp')"

# now get the module location
i="$(grep '^[[:space:]]*DEST_MODULE_LOCATION[[:space:]]*\[0\][[:space:]]*=' dkms.conf)"
new_location="$(echo "$i" | sed -n 's|^[^=]*=[[:space:]]*\"\([^\"]*\).*$|\1|p')"

# get the kernel version of the running system
running="$(uname -r)"

# check if the module shall be handled on the running system 
if [ "${running}" = "${kernelver}" ];
then
	# yes!
	# we have to take some actions before initrd preparation
	cur=0
	end=$(echo "$all_names" | wc -l)
	while [ $cur -lt $end ];
	do
		# get the current module name
		cur=$(expr $cur + 1)
		name="$(echo "$all_names" | sed -n "${cur}p")"
		# search the module
		modules="$(find /lib/modules/${kernelver}/ -type f -name "${name}".*)"
		# check if the module is active
		active=$(lsmod | grep -c "${name}")
		if [ $active -ne 0 ];
		then
			# it is active!
			# remove it
			rmmod "$name"
			if [ "${what}" = "install" ];
			then
				# module shall be installed
				# search the new compiled one
				module="$(echo "${modules}" | grep "/lib/modules/[^/]*${new_location}/")"
			else
				# module shall be removed
				# search the original one
				module="$(echo "${modules}" | grep '/lib/modules/[^/]*/kernel/')"
			fi
			# and insert the module
			insmod "${module}"
		fi
	done
fi

depmod "${kernelver}"

# now update the initramfs
update-initramfs -u -k "${kernelver}"

# and exit with the exit code of update-initramfs
exit $?
