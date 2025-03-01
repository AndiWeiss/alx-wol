#!/bin/sh

# this script handles the initrd creation

# $1: kernel version to handle
# $2: install or remove
# $3: complete path of original module
# $4: complete path of new module
kernelver="$1"
what="$2"
orig_location="$3"
new_location="$4"

# get the name of the module out of the dkms.conf file
i="$(grep '^[[:space:]]*BUILT_MODULE_NAME[[:space:]]*\[[0-9]\{1,\}\][[:space:]]*=' dkms.conf)"
# maybe there is more than one ...
all_names="$(echo "$i" | sed -n 's|^[^"]*"\([^"]*\).*$|\1|gp')"

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
				# use the new compiled one
				module="$new_location"
			else
				# module shall be removed
				# use the original one
				module="$orig_location"
			fi
			# and insert the module
			module="$(find $module -name ${name}.*)"
			insmod "${module}"
		fi
	done
fi

depmod "${kernelver}"

# now update the initramfs
# check if dracut is available
which dracut > /dev/null 2>&1
if [ $? -eq 0 ]; then
	# yes, use it
	dracut --force ${kernelver}
else
	# dracut not available
	# check if update-initramfs is available
	which update-initramfs > /dev/null 2>&1
	if [ $? -eq 0 ]; then
		# yes, use it
		update-initramfs -u -k "${kernelver}"
	else
		# update-initramfs not available
		# use mkinitcpio
		mkinitcpio -P -k "${kernelver}"
	fi
fi

# and exit with the exit code of initramfs update program
exit $?
