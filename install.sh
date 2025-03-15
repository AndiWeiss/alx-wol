#!/bin/sh

# install the dkms system for this module
# which module is defined in dkms.conf
# the required config is done in sources.txt

script="$(basename "$0")"

# script requires root rights
# check if we're root
user=$(whoami)
if [ "$user" != "root" ]; then
	# no, exit with error
	echo "${script}: this has to be executed as root!" 1>&2
	exit 1
fi

# check if dkms is installed
chk="$(which dkms)"
if [ -z $chk ]; then
	# no, exit with error
	echo "${script}: usage requires dkms!" 1>&2
	exit 1
fi

# check if wget is installed
chk="$(which wget)"
if [ -z $chk ]; then
	# no, exit with error
	echo "${script}: usage requires wget!" 1>&2
	exit 1
fi

# the following part checks if the required information
# (kernel version and used gcc version) can be extracted
# from the running kernel
export kernelver=$(uname -r)

# check if linux headers are available
if [ ! -d /lib/modules/$kernelver ]; then
	# no, exit with error
	echo "linux headers not found." 1>&2
	echo "expect them at /lib/modules/$(uname -r)" 1>&2
	exit 1
fi

# check if a compiler is available
if [ "$(which gcc)" = "" ]; then
	# no gcc available
	echo "$(basename $0): it seems there is no gcc available" >&2
	echo "gcc is required for building modules" >&2
	exit 1
fi

# get the package name out of dkms.conf
this_name="$(grep '^[^#]*PACKAGE_NAME=' dkms.conf | sed -n 's|.*PACKAGE_NAME=\"||g;s|\"$||g;p')"

# get the version out of dkms.conf
this_version="$(grep '^[^#]*PACKAGE_VERSION=' dkms.conf | sed -n 's|.*PACKAGE_VERSION=\"||g;s|\"$||g;p')"

# get the module name out of dkms.conf
this_module_name="$(grep '^[^#]*BUILT_MODULE_NAME\[0\]=' dkms.conf | sed -n 's|.*BUILT_MODULE_NAME\[0\]=\"||g;s|\"$||g;p')"

# check if the package is installed
installed="$(dkms status | grep "^${this_name}/")"
if [ "${installed}" != "" ]; then
	# yes, ask if they shall be removed
	echo "found other versions of ${this_name} installed"
	doit="N"
	echo -n "	shall they all be removed [y/N]? "
	read doit
	if [ "${doit}" = "y" ] || [ "${doit}" = "Y" ]; then
		# shall be removed
		i=0
		last=$(echo "${installed}" | wc -l)
		while [ $i -lt $last ]; do
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

# install the update-initramfs hook
# check if update-initramfs is available
which update-initramfs > /dev/null 2>&1
if [ $? -eq 0 ]; then
	# yes
	# check if hook directory exists
	if [ -d /etc/initramfs-tools/hooks ]; then
		# yes
		# this is mandatory for ubuntu 23.x
		# otherwise the module will not be installed in the initrd
		# we don't care if there is already a hook file!
		cp dkms-adder /etc/initramfs-tools/hooks
	else
		# if the hook directory is not available we don't
		# know how to continue ...
		# the dkms system wil be functional, but it may happen that the
		# module isn't included in the initrd.
		echo "/etc/initramfs-tools/hooks doesn't exist"
		echo "continue installation, update of initramfs may fail"
	fi
fi

if [ -d "/usr/src/${this_name}-${this_version}" ]; then
	# if the same version of this package is already installed
	# we replace it
	rm -rf "/usr/src/${this_name}-${this_version}"
fi

# (re)create the source directory
mkdir "/usr/src/${this_name}-${this_version}"

# get all files of this package
all_files="$(ls)"

# copy all files except those which are not required
# for dkms into the source directory
i=0
last=$(echo "${all_files}" | wc -l)
while [ $i -lt $last ]; do
	i=$(expr $i + 1)
	file="$(echo "${all_files}" | sed -n "${i}p")"
	if [ "${file}" != "${script}" ] \
		&& [ "${file}" != "README.md" ] \
		&& [ "${file}" != "dkms-adder" ] \
		&& [ "${file}" != "remove.sh" ] \
		&& [ "${file}" != "kernelpatching.md" ] \
		&& [ "${file}" != "kernelsources" ] \
		&& [ "${file}" != "other_examples" ];
	then
		cp --preserve=mode,timestamps -r "${file}" "/usr/src/${this_name}-${this_version}/"
	fi
done

# install the module
dkms install -m "${this_name}" -v "${this_version}"
if [ $? -eq 0 ]; then
	echo "#### installation of ${this_name} version ${this_version} succeeded ####"
else
	echo "#### FAILED installation of ${this_name} version ${this_version} ####"
fi
