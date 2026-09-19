#!/usr/bin/sh

# install the dkms system for this module
# which module is defined in dkms.conf
# the required config is done in sources.txt

script="$(basename "$0")"
gitcall="$(dirname $0)/scripts/gitcall.sh"
llr_file=local-linux-repo

warn_suse ()
{
	grep -i 'ID=.*SUSE' /etc/os-release > /dev/null 2>&1
	if [ $? -eq 0 ]; then
		if [ ! -f /usr/sbin/dkms_wrapper.sh ]; then
			echo "*******************************************"
			echo "***   This seems to be a suse system    ***"
			echo "***     dkms_wrapper.sh is missing      ***"
			echo "***   please take care to modify the    ***"
			echo "*** installation according to README.md ***"
			echo "*******************************************"
			exit 1
		fi
		grep 'dkms_wrapper\.sh' /usr/lib/systemd/system/dkms.service > /dev/null 2>&1
		if [ $? -ne 0 ]; then
			echo "*******************************************"
			echo "***   This seems to be a suse system    ***"
			echo "***      dkms.service doesn't call      ***"
			echo "***  dkms_warpper.sh. Check README.md   ***"
			echo "***      for correct installation       ***"
			echo "*******************************************"
			exit 1
		fi
		find /etc/systemd -type l | grep -c 'dkms\.service' > /dev/null 2>&1
		if [ $? -ne 0 ]; then
			echo "*******************************************"
			echo "***   This seems to be a suse system    ***"
			echo "***  dkms.service seems to be disabled  ***"
			echo "***     Check README.md for correct     ***"
			echo "***            installation             ***"
			echo "*******************************************"
			exit 1
		fi
	fi
}

warn_suse_git ()
{
	grep -i 'ID=.*SUSE' /etc/os-release > /dev/null 2>&1
	if [ $? -eq 0 ]; then
		if [ "$(stat -c %U "${local_linux_repo}/.git")" != "root" ]; then
			echo "*******************************************"
			echo "*** suse requires the local linux repo  ***"
			echo "*** owned by root. This is not the case ***"
			echo "***    !!!! dkms run will fail !!!!     ***"
			echo "*******************************************"
			exit 1
		fi
	fi
}

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

warn_suse

if [ $# -gt 0 ]; then
	echo "$1" | grep -c '^local-linux-repo=' >> /dev/null 2>&1
	if [ $? -ne 0 ]; then
		echo "only local-linux-repo=... accepted as parameter"
		exit 1
	fi
	local_linux_repo="$(realpath "$(echo "$1" | sed 's|local-linux-repo=||')")"
	if [ ! -d "${local_linux_repo}" ]; then
		echo "no directory ${local_linux_repo}"
		doit="N"
		echo -n "	shall the kernel repo be cloned there [y/N]? "
		read doit
		if [ "${doit}" = "y" ] || [ "${doit}" = "Y" ]; then
			mkdir -p "${local_linux_repo}"
			if [ $? -ne 0 ]; then
				echo "error creating directory ${local_linux_repo}"
				exit 1
			fi
			git clone https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux "${local_linux_repo}"
			if [ $? -ne 0 ]; then
				echo "error on cloning kernel repo"
				exit 1
			fi
		else
			echo "no kernel repo found at ${local_linux_repo}"
			exit 1
		fi
	fi
	warn_suse_git
	${gitcall} -C "${local_linux_repo}" status > /dev/null 2>&1
	if [ $? -ne 0 ]; then
		echo "${local_linux_repo} seems to be no git repo"
		exit 1
	fi
	if [ ! -f "${local_linux_repo}/README" ] ||
	[ "$(grep -n '^Linux kernel$' "${local_linux_repo}/README")" != "1:Linux kernel" ]; then
		echo "${local_linux_repo} seems to be no kernel"
		exit 1
	fi
	echo "local-linux-repo=${local_linux_repo}" > ${llr_file}
else
	rm -f ${llr_file}
fi

if [ ! -f ${llr_file} ]; then
	# check if wget is installed
	chk="$(which wget)"
	if [ -z $chk ]; then
		# no, exit with error
		echo "${script}: usage requires wget!" 1>&2
		exit 1
	fi
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
if [ "$(which gcc)" = "" ] && [ "$(which clang)" = "" ]; then
	# no compiler available
	echo "$(basename $0): it seems there is no compiler (gcc or clang) available" 1>&2
	echo "a compiler is required for building modules" 1>&2
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
		&& [ "${file}" != "tools" ] \
		&& [ "${file}" != "other_examples" ];
	then
		cp --preserve=mode,timestamps -r "${file}" "/usr/src/${this_name}-${this_version}/"
	fi
done

# install the module
dkms install -m "${this_name}" -v "${this_version}"
if [ $? -eq 0 ]; then
	echo "#### installation of ${this_name} version ${this_version} succeeded ####"
	exit 0
else
	echo "#### FAILED installation of ${this_name} version ${this_version} ####"
	exit 1
fi
