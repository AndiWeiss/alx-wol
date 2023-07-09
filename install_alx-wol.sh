#!/bin/sh

script=$(basename $0)
alx_wol_dir="$(dirname $0)"

export $( grep -vE "^(#.*|\s*)$" filelist )

mk_dir () {
	mkdir "$1"
	if [ $? -ne 0 ];
	then
		exit 1
	fi
}

cp_exit () {
	cp "$1" "$2"
	if [ $? -ne 0 ];
	then
		exit 1
	fi
}

user=$(whoami)
if [ "$user" != "root" ];
then
	echo "${script}: this has to be executed as root!" 1>&2
	exit 1
fi

force=0
if [ $# -eq 1 ];
then
	if [ "$1" == "--force" ];
	then
		force=1
	fi
fi

this_name="$(grep '^[^#]*PACKAGE_NAME=\"' ${alx_wol_dir}/dkms.conf | sed -n 's|.*PACKAGE_NAME=\"||g;s|\"$||g;p')"
this_version="$(grep '^[^#]*PACKAGE_VERSION=\"' ${alx_wol_dir}/dkms.conf | sed -n 's|.*PACKAGE_VERSION=\"||g;s|\"$||g;p')"
patches="$(find patches -type f)"
modulename="$(grep '^[^#]*BUILT_MODULE_NAME\[0\]=\"' ${alx_wol_dir}/dkms.conf | sed -n 's|.*BUILT_MODULE_NAME\[0\]=\"||g;s|\"$||g;p')"

chk=$(which dkms)
if [ -z $chk ];
then
	echo "${script}: usage of this ${this_name} requires dkms!" 1>&2
	exit 1
fi

current=$(dkms status | grep "^${this_name}/" | sed -n 's|,.*||g;p')
if [ ! -z "${current}" ];
then
	echo "found \"${current}\" installed"

	cur_ver="$(echo "${current}" | sed -n 's|^.*/||g;p')"
	if [ "${cur_ver}" != "${this_version}" ];
	then
		if [ "${cur_ver}" = "1.3" ];
		then
			# fix a problem in deinstallation of 1.3
			cp_exit "${alx_wol_dir}/HandleInitrd.sh" "/usr/src/${this_name}-${cur_ver}"
		fi
		if [ $force -eq 0 ];
		then
			echo "----> \"${this_name}/${this_version}\" will be installed"
			echo "      before doing so current installed version"
			echo "      \"${current}\" will be removed."
			echo -n "SHALL TIHS BE DONE (enter yes)? "
			read answer
		else
			answer="yes"
		fi
		if [ "${answer}" != "yes" ];
		then
			echo "installation aborted,"
			exit 1
		else
			dkms remove ${this_name}/${cur_ver} --all
			if [ $? -ne 0 ];
			then
				echo "${script}: removal of \"${current}\" failed" 1>&2
				exit 1
			fi
			# need to be sure that kernel.org is available
			# otherwise the next fetch may fail
			while [ true ];
			do
				ping -c 1 www.kernel.org &> /dev/null
				if [ $? = 0 ];
				then
					break
				fi
				sleep 1
			done
		fi
	else
		# this version is already installed
		echo "exit because this version is already installed"
		exit 0
	fi
fi

# next step:
# create /usr/src/<name>-<version>
basedir="/usr/src/${this_name}-${this_version}"

mk_dir ${basedir}

# create dir for patches
mk_dir ${basedir}/patches

# copy all required files
for patch in ${patches};
do
	cp_exit "${alx_wol_dir}/${patch}" "${basedir}/patches"
done
cp_exit "${alx_wol_dir}/dkms.conf" "${basedir}"
cp_exit "${alx_wol_dir}/filelist" "${basedir}"
cp_exit "${alx_wol_dir}/Makefile" "${basedir}"
cp_exit "${alx_wol_dir}/FetchSources.sh" "${basedir}"
cp_exit "${alx_wol_dir}/HandleInitrd.sh" "${basedir}"

dkms install ${this_name}/${this_version}
if [ $? -ne 0 ];
then
	echo "${script}: installation of \"${this_name}/${this_version}\" failed" 1>&2
	exit 1
fi

echo "${script}: installation of \"${this_name}/${this_version}\" succeeded"
