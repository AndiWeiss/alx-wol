#!/bin/bash
# 	url = file:///home/administrator/other/home/administrator/alx-wol/

lines="$(echo "$1" | sed 's|^[^=]*=||'|tr ' ' '\n')"

pattern="^[0-9]\\+\\.[0-9]\\+\\.[0-9]\\+$"

if [ "$(echo "${lines}" | grep -ic gcc)" -gt 0 ]; then
	compiler="gcc"
	if [ "$(echo "${lines}" | grep -c "${pattern}")" -eq 1 ]; then
		version="$(echo "${lines}" | grep "${pattern}" | sed 's|^[^0-9]*\(${pattern}\)[^0-9]*$|\1|')"
	fi
elif [ "$(echo "${lines}" | grep -ic clang)" -gt 0 ]; then
	compiler="clang"
	if [ "$(echo "${lines}" | grep -c "${pattern}")" -eq 1 ]; then
		version="$(echo "${lines}" | grep "${pattern}" | sed 's|^[^0-9]*\(${pattern}\)[^0-9]*$|\1|')"
	fi
fi

if [ "${compiler}" != "" ] && [ "${version}" != "" ]; then
	echo "${compiler} ${version}"
fi
