#!/bin/bash

export $( grep -vE "^(#.*|\s*)$" ${PWD}/filelist )

if [ -z "${kernelver}" ];
then
	if [ -f "${kernelver_file}" ];
	then
		export $( grep -vE "^(#.*|\s*)$" ${kernelver_file} )
		rm ${kernelver_file}

		depmod
		update-initramfs -u -k ${lastversion}

		export $( grep -vE "^(#.*|\s*)$" ${module_file} )
		echo "${current_module}" | grep "/kernel/drivers/net/ethernet/atheros/alx/alx.ko.*$" > /dev/null
		if [ $? -ne 0 ];
		then
			rmmod alx
			mod=$(find /usr/lib/modules/$(uname -r)/kernel/drivers/net/ethernet/atheros/alx -name 'alx.ko*')
			insmod ${mod}
		fi
	fi
else
	echo "lastversion=${kernelver}" > ${kernelver_file}

	depmod
	update-initramfs -u -k ${kernelver}

	export $( grep -vE "^(#.*|\s*)$" ${module_file} )
	echo "${current_module}" | grep "/kernel/drivers/net/ethernet/atheros/alx/alx.ko.*$" > /dev/null
	if [ $? -eq 0 ];
	then
		rmmod alx
		mod=$(find /usr/lib/modules/$(uname -r)/updates/dkms -name 'alx.ko*')
		insmod ${mod}
	fi

	rm ${module_file}
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
