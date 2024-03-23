#!/bin/sh

# remove the dkms system for this module
# which module is defined in dkms.conf
# the required config is done in sources.txt

script="$(basename "$0")"

# script requires root rights
# check if we're root
user=$(whoami)
if [ "$user" != "root" ];
then
	# no, exit with error
	echo "${script}: this has to be executed as root!" 1>&2
	exit 1
fi

# check if dkms is installed
chk="$(which dkms)"
if [ -z $chk ];
then
	# no, exit with error
	echo "${script}: usage requires dkms!" 1>&2
	exit 1
fi

# get the pagage name out of dkms.conf
this_name="$(grep '^[^#]*PACKAGE_NAME=\"' dkms.conf | sed -n 's|.*PACKAGE_NAME=\"||g;s|\"$||g;p')"

# get the version out of dkms.conf
this_version="$(grep '^[^#]*PACKAGE_VERSION=\"' dkms.conf | sed -n 's|.*PACKAGE_VERSION=\"||g;s|\"$||g;p')"

# get the module name out of dkms.conf
this_module_name="$(grep '^[^#]*BUILT_MODULE_NAME\[0\]=\"' dkms.conf | sed -n 's|.*BUILT_MODULE_NAME\[0\]=\"||g;s|\"$||g;p')"

# check if the package is installed
installed="$(dkms status | grep "^${this_name}/")"
if [ "${installed}" != "" ];
then
	# yes, ask if they shall be removed
	echo "found versions of ${this_name} installed"
	doit="N"
	echo -n "	shall they all be removed [y/N]? "
	read doit
	if [ "${doit}" = "y" ] || [ "${doit}" = "Y" ];
	then
		# shall be removed
		i=0
		last=$(echo "${installed}" | wc -l)
		while [ $i -lt $last ];
		do
			# remove each single dkms instance
			i=$(expr $i + 1)
			line="$(echo "${installed}" | sed -n "${i}p")"
			remove_version="$(echo "${line}" | sed -n 's|^[^/]*/\([^,]*\),.*$|\1|p')"
			remove_kernel="$(echo "${line}" | sed -n 's|^[^,]*,[[:space:]]*\([^,]*\),.*$|\1|p')"
			remove_arch="$(echo "${line}" | sed -n 's|^[^,]*,[^,]*,[[:space:]]*\([^:]*\):.*$|\1|p')"

			echo "remove ${this_name} ${remove_version} ${remove_kernel} ${remove_arch} ..."
			dkms remove -m "${this_name}" -v "${remove_version}" -k "${remove_kernel}" -a "${remove_arch}"
		done

		# now remove the sources
		rm -rf "/var/lib/dkms/${this_name}"

		# removal succeeded
		echo "deinstallation of ${this_name} completed"
	else
		echo "please deinstall all ${this_name} versions manually"
		exit 1
	fi
fi

# remove the update-initramfs hook
if [ -d /etc/initramfs-tools/hooks ] && [ -f /etc/initramfs-tools/hooks/dkms-adder ];
then
	rm /etc/initramfs-tools/hooks/dkms-adder
fi
