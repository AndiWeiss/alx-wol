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
		echo "${current_module}" | grep "/kernel/drivers/net/ethernet/atheros/alx/alx.ko$" > /dev/null
		if [ $? -ne 0 ];
		then
			rmmod alx
			insmod /usr/lib/modules/$(uname -r)/kernel/drivers/net/ethernet/atheros/alx/alx.ko
		fi
	fi
else
	echo "lastversion=${kernelver}" > ${kernelver_file}

	depmod
	update-initramfs -u -k ${kernelver}

	export $( grep -vE "^(#.*|\s*)$" ${module_file} )
	echo "${current_module}" | grep "/kernel/drivers/net/ethernet/atheros/alx/alx.ko$" > /dev/null
	if [ $? -eq 0 ];
	then
		rmmod alx
		insmod /usr/lib/modules/$(uname -r)/updates/dkms/alx.ko
	fi

	rm ${module_file}
fi
