#!/bin/sh

log_it()
{
	echo "$*" >> /log.txt
}

log_it "XXXXXXXXXXXXXX $0 started >$*< XXXXXXXXXXXXXX"

temp="$(realpath -s "${PWD}/../temp")"

module_name="$(cat "${temp}/module_name")"

mod_available=$(lsmod | grep -c "^${module_name}")
if [ $mod_available -ne 0 ];
then
	echo "XXXXXXXXXX austauschen XXXXXXXXXXXXXXXXX"
else
	echo "XXXXXXXXXX nicht geladen XXXXXXXXXXXXXXXXX"
fi
