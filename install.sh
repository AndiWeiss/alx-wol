#!/bin/sh

# install the dkms system for this module
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

# check if a compiler is available
if [ "$(which gcc)" = "" ];
then
	# no gcc available
	echo "$(basename $0): it seems there is no gcc available" >&2
	echo "gcc is required for building modules" >&2
	exit 1
fi

# the following part checks if the required information
# (kernel version and used gcc version) can be extracted
# from the running kernel
temp=.temp
export kernelver=$(uname -r)
kernel="/boot/vmlinuz-${kernelver}"
major=$(uname -r | sed -n 's|^\([0-9]\+\)\..*$|\1|g;p')
minor=$(uname -r | sed -n 's|^[0-9]\+\.\([0-9]\+\)\..*$|\1|g;p')
versionstringfile=${temp}/kernel_version_string
versionfile=${temp}/kernel_version
gccversionfile=${temp}/gcc_used

if [ -d "${temp}" ];
then
	rm -rf "${temp}"
fi
mkdir ${temp}

wget -nv -O "${temp}/extract-vmlinux" https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/plain/scripts/extract-vmlinux?h=v$(uname -r | sed -n 's|\.[^.]*$||p')
if [ $? -ne 0 ];
then
	# exit if it can't be fetched
	echo "$(basename $0): no extract-vmlinux available" >&2
	exit 1
else
	# use it
	chmod +x "${temp}/extract-vmlinux"
	"${temp}/extract-vmlinux" "${kernel}" > "${temp}/vmlinux"
fi
if [ $? -ne 0 ];
then
	# extraction failed, exit with error
	echo "$(basename $0): ${kernel} seems not to be a vmlinuz file" >&2
	exit 1
fi

# now we have the uncompressed vmlinux file
vmlinux="${temp}/vmlinux"

# search for a sensefull string in the file
strings "${vmlinux}" | grep "^Linux version $major\.$minor" > "${versionstringfile}"

# check if the file contains a sensefull version string
i=$(grep -c "^Linux version $major\.$minor" "${versionstringfile}")
if [ $i -eq 0 ];
then
	# no, exit with error
	echo "$(basename $0): ${vmlinux} seems not to be a vmlinux file" >&2
	rm "${versionstringfile}"
	exit 1
fi

# extract the kernel version
./scripts/extract_kversion.sh "${versionstringfile}" "${versionfile}"
if [ $i -eq 0 ];
then
	# failed, exit with error
	echo "$(basename $0): ${vmlinux} seems not to be a known kernel" >&2
	exit 1
fi

# extract the used gcc version
./scripts/gcc_used.sh "${versionstringfile}" "${gccversionfile}"
if [ $i -eq 0 ];
then
	# failed, exit with error
	echo "$(basename $0): can't detect gcc used for ${vmlinux}" >&2
	exit 1
fi

# now check if the required headers are available
if [ ! -d "/usr/src/linux-headers-${kernelver}" ];
then
	# headers for running system are not available
	echo "$(basename $0): linux headers required for ${kernelver} are not available" >&2
	echo "If you want to use alx-wol: you have to take care that before installing" \
		"a new kernel the headers are available. Otherwise dkms will skip the installation." >&2
	echo "There are Linux distributions which don't take care for the required dependencies." >&2
	echo "After header installation execute a reboot - sometimes the kernel gets installed" \
		"together with the headers. In that case the new installed kernel has to run before" \
		"alx-wol installation." >&2
	exit 1
fi

# work done, remove the temporary files
rm -rf "${temp}"

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
	echo "found other versions of ${this_name} installed"
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

# install the update-initramfs hook
if [ -d /etc/initramfs-tools/hooks ];
then
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

if [ -d "/usr/src/${this_name}-${this_version}" ];
then
	# if the same version of this package is already installed
	# we replace it
	rm -rf "/usr/src/${this_name}-${this_version}"
fi

# (re)create the source directory
mkdir "/usr/src/${this_name}-${this_version}"

# get all files of this package
all_files="$(ls)"

# copy all file except the Readme and the examples into the source
# directory
i=0
last=$(echo "${all_files}" | wc -l)
while [ $i -lt $last ];
do
	i=$(expr $i + 1)
	file="$(echo "${all_files}" | sed -n "${i}p")"
	if [ "${file}" != "${script}" ] \
		&& [ "${file}" != "README.md" ] \
		&& [ "${file}" != "kernelpatching.md" ] \
		&& [ "${file}" != "other_examples" ];
	then
		cp -r "${file}" "/usr/src/${this_name}-${this_version}/"
	fi
done

# take care that there is a dkms.conf
if [ -f "/usr/src/${this_name}-${this_version}/dkms.conf" ];
then
	# and set the correct access rights
	sudo chmod 644 "/usr/src/${this_name}-${this_version}/dkms.conf"
else
	echo "didn't find dkms.conf"
fi

# install the module
dkms install -m "${this_name}" -v "${this_version}"
if [ $? -eq 0 ];
then
	echo "#### installation of ${this_name} version ${this_version} succeeded ####"
else
	echo "#### FAILED installation of ${this_name} version ${this_version} ####"
fi
