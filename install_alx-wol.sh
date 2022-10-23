#!/bin/sh

kernel_version="v6.0.3"

get_source () {
	wget -O ${targetdir}/$1 https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/plain/drivers/net/ethernet/atheros/alx/$1?h=${kernel_version}
	if [ $? -ne 0 ];
	then
		exit 1
	fi
}

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

tmpfile=".target"
handle () {
	rm "${tmpfile}"
	while read -r line;
	do
		echo "${line}"
		if [ ! -z "`echo "${line}" | grep "/alx-wol/.*/alx.ko"`" ];
		then
			echo "${line}" | sed -n 's|^[^/]*/|/|p' > ${tmpfile}
		fi
	done
}

user=`whoami`
if [ "$user" != "root" ];
then
	echo "`basename $0`: this has to be executed as root!" 1>&2
	exit 1
fi

this_name="`grep '^[^#]*PACKAGE_NAME=\"' dkms.conf | sed -n 's|.*PACKAGE_NAME=\"||g;s|\"$||g;p'`"
this_version="`grep '^[^#]*PACKAGE_VERSION=\"' dkms.conf | sed -n 's|.*PACKAGE_VERSION=\"||g;s|\"$||g;p'`"
this_patch="`grep '^[^#]*PATCH\[0\]=\"' dkms.conf | sed -n 's|.*PATCH\[0\]=\"||g;s|\"$||g;p'`"
modulename="`grep '^[^#]*BUILT_MODULE_NAME\[0\]=\"' dkms.conf | sed -n 's|.*BUILT_MODULE_NAME\[0\]=\"||g;s|\"$||g;p'`"

chk=`which dkms`
if [ -z $chk ];
then
	echo "`basename $0`: usage of this ${this_name} requires dkms!" 1>&2
	exit 1
fi

current=`dkms status | grep "^${this_name}/" | sed -n 's|,.*||g;p'`
if [ ! -z ${current} ];
then
	echo "found \"${current}\" installed"

	cur_ver="`echo "${current}" | sed -n 's|^.*/||g;p'`"
	if [ "${cur_ver}" != "${this_version}" ];
	then
		echo "----> \"${this_name}/${this_version}\" will be installed"
		echo "      before doing so current installed version"
		echo "      \"${current}\" will be removed."
		echo -n "SHALL TIHS BE DONE (enter yes)? "
		read answer
		if [ "${answer}" != "yes" ];
		then
			echo "installation aborted,"
			exit 1
		fi
	fi
fi

# next step:
# create /usr/src/<name>-<version>
basedir="/usr/src/${this_name}-${this_version}"
mk_dir ${basedir}

# create dir for sources
targetdir="${basedir}/alx"
mk_dir ${targetdir}

# fetch sources
get_source alx.h
get_source ethtool.c
get_source hw.c
get_source hw.h
get_source main.c
get_source Makefile
get_source reg.h

# create dir for patches
mkdir ${basedir}/patches

# copy all required files
cp_exit "patches/${this_patch}" "${basedir}/patches"
cp_exit "dkms.conf" "${basedir}"
cp_exit "Makefile" "${basedir}"

if [ ! -z ${current} ];
then
	dkms remove -m ${this_name} -v ${cur_ver}
	if [ $? -ne 0 ];
	then
		echo "`basename $0`: removal of \"${current}\" failed" 1>&2
		exit 1
	fi
fi

dkms install -m ${this_name} -v ${this_version} | handle
if [ $? -ne 0 ];
then
	echo "`basename $0`: installation of \"${this_name}/${this_version}\" failed" 1>&2
	exit 1
fi

echo "Ergebnis: >${chk}<"

echo "`basename $0`: installation of \"${this_name}/${this_version}\" succeeded"

if [ -f "${tmpfile}" ];
then
	module2load=`cat ${tmpfile}`
	rm "${tmpfile}"

	echo "`basename $0`: removing module ${modulename} ..."
	rmmod ${modulename}
	if [ $? -ne 0 ];
	then
		echo "`basename $0`: error on removal of ${modulname}"
		echo "nevertheless try to load new compiled module ..."
	fi

	echo "`basename $0`: inserting module ${module2load} ..."
	insmod ${module2load}
	if [ $? -ne 0 ];
	then
		echo "`basename $0`: error on installation of ${module2load}"
		exit 1
	fi
fi
