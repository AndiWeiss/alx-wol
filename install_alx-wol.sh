#!/bin/sh

alx_wol_dir="`dirname $0`"

mk_dir () {
	mkdir "$1"
	if [ $? -ne 0 ];
	then
		exit 1
	fi
}

cp_exit () {
	cp -p "$1" "$2"
	if [ $? -ne 0 ];
	then
		exit 1
	fi
}

tmpfile="${alx_wol_dir}/.target"
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

force=0
if [ $# -eq 1 ];
then
	if [ "$1" == "--force" ];
	then
		force=1
	fi
fi

this_name="`grep '^[^#]*PACKAGE_NAME=\"' ${alx_wol_dir}/dkms.conf | sed -n 's|.*PACKAGE_NAME=\"||g;s|\"$||g;p'`"
this_version="`grep '^[^#]*PACKAGE_VERSION=\"' ${alx_wol_dir}/dkms.conf | sed -n 's|.*PACKAGE_VERSION=\"||g;s|\"$||g;p'`"
patches="`find patches -type f`"
modulename="`grep '^[^#]*BUILT_MODULE_NAME\[0\]=\"' ${alx_wol_dir}/dkms.conf | sed -n 's|.*BUILT_MODULE_NAME\[0\]=\"||g;s|\"$||g;p'`"

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
		fi
	fi
fi

# next step:
# create /usr/src/<name>-<version>
basedir="/usr/src/${this_name}-${this_version}"
mk_dir ${basedir}

# create dir for patches
mkdir ${basedir}/patches

# copy all required files
for patch in ${patches};
do
	cp_exit "${alx_wol_dir}/${patch}" "${basedir}/patches"
done
cp_exit "${alx_wol_dir}/dkms.conf" "${basedir}"
cp_exit "${alx_wol_dir}/Makefile" "${basedir}"
cp_exit "${alx_wol_dir}/FetchSources.sh" "${basedir}"

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
