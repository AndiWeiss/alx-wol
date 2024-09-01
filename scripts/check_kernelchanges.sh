#!/bin/bash

# Parameter
# 1: path to kernel git repo
# 2: path inside kernel which shall be checked

src="$1"
path="$2"

if [ $# -ne 2 ]; then
	echo "$(basename $0) requires two parameters:"
	echo "first parameter: path to linux git repository"
	echo "second parameter: path inside linux sources"
	exit 1
fi

git -C "${src}" status > /dev/null
if [ $? -ne 0 ]; then
	echo "it seems ${src} is no git repo"
	exit 1
fi

if [ ! -d "${src}/${path}" ]; then
	echo "${src}/${path} doesn't exist"
	exit 1
fi

# 1st step: get all tags to check
all_tags="$(git -C "${src}" tag --list |grep -v -e '-rc' | grep 'v[5-9]')"
if [ "${all_tags}" = "" ]; then
	echo "no matching tags found in ${src}"
	exit 1
fi

list_un=""
for v in ${all_tags}; do
	maj=$(echo "$v" | sed -n 's|^v\([0-9]\{1,\}\)\..*$|\1|g;p')
	min=$(echo "$v" | sed -n 's|^v[0-9]\{1,\}\.\([0-9]\{1,\}\).*$|\1|g;p')
	if [ $(echo "$v" | grep -c '\..*\.') -eq 1 ]; then
		pat=$(echo "$v" | sed -n 's|^v[0-9]\{1,\}\.[0-9]\{1,\}\.\([0-9]\{1,\}\).*$|\1|g;p')
	else
		pat=0
	fi
	if [ "${list_un}" = "" ]; then
		list_un="$(printf "%03d.%03d.%03d" ${maj} ${min} ${pat})"
	else
		list_un="$(printf "%s %03d.%03d.%03d" "${list_un}" ${maj} ${min} ${pat})"
	fi
done

list="$(echo "$(for v in ${list_un}; do echo "$v"; done)" | sort)"

line() {
	maj=$(echo "$1" | sed -n 's|^0*||g;s|\..*$||g;p')
	min=$(echo "$1" | sed -n 's|^[^.]*\.0*||g;s|\..*$||g;p')
	if [ "${min}" = "" ]; then
		min="0"
	fi
	pat=$(echo "$1" | sed -n 's|^[^.]*\.[^.]*\.0*||g;p')
	if [ "$pat" = "" ]; then
		echo "v${maj}.${min}"
	else
		echo "v${maj}.${min}.${pat}"
	fi
}

prev=""
for h in $list; do
	if [ "$prev" = "" ]; then
		prev="$(line $h)"
		continue;
	fi
	cur="$(line $h)"
#	echo "Vergleiche $cur mit $prev"
	res="$(git -C "${src}" diff "${prev}" "${cur}" "${path}")"
	if [ "${res}" != "" ]; then
		printf "differences found from %-12s to %-12s\n" "${prev}" "${cur}"
	fi
	prev="${cur}"
done
