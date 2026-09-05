#!/usr/bin/bash

# Parameter:
# 1: Pfad auf kernel repo
# 2: Pfad innerhalb der sources
# 3: wohin schreiben

if [ $# -ne 3 ]; then
	echo "call $(basename $0):"
	echo "$(basename $0) <path_to_kernel_repo> <path_inside_kernel> <where_to_write>"
	exit 1
fi

kernel_repo="$(realpath "$1")"
path_inside="$2"
write_to="$3"

if [ ! -d "${kernel_repo}" ]; then
	echo "${kernel_repo} doesn't exist"
	exit 1
fi

git -C "${kernel_repo}" status >/dev/null 2>&1
if [ $? -ne 0 ]; then
	echo "${kernel_repo} seems not to contain a git repo"
	exit 1
fi

#if [ ! -d "${kernel_repo}/${path_inside}" ]; then
#	echo "${kernel_repo}/${path_inside} doesn't exist"
#	exit 1
#fi

if [ ! -d "${write_to}" ]; then
	echo "${write_to} doesn't exist"
	exit 1
fi

all_tags="$(git -C "${kernel_repo}" tag | grep '^v[0-9]\+.*\.[0-9]\+$')"
all_versions="$(echo "${all_tags}" | sed 's|\([0-9]\+\)|000\1|g;s|0*\([0-9]\{3,3\}\)|\1|g;s|^\(.\{8,8\}\)$|\1.000|' | grep '^.\{12,12\}$'| sort)"

# gitcopy
# parameter:
# 1: kernel repo
# 2: tag
# 3: pfad im kernel tree
# 4: wohin
gitcopy () {
	git -C "$1" checkout $2 > /dev/null 1>&2
	if [ -d "$1/$3" ]; then
		mkdir "$4/$2"
		cp -r "$1/$3" "$4/$2"
	fi
}

get_tag () {
	echo "$1" | sed 's|v0*\([0-9]\+\)\.0*\([0-9]\+\)\.0*\([0-9]\+\)$|v\1.\2.\3|g;s|\.0$||'
}

for version in ${all_versions}; do
	if [ $(echo $version | sed 's|v\([^.]*\).*$|\1|') -lt 5 ]; then
		continue
	fi

	if [ $(echo $version | sed 's|v\([^.]*\).*$|\1|') -eq 5 ] && \
		[ $(echo $version | sed 's|v[^.]*\.\([^.]*\).*$|\1|') -lt 15 ]; then
		continue
	fi

	if [ "${prev_version:0:4}" != "${version:0:4}" ] || [ "${prev_version:4:4}" != "${version:4:4}" ]; then
		prev_version=""
	fi

	tag="$(get_tag "${version}")"

	if [ ! -d "${write_to}/${tag}" ]; then
		if [ "${prev_version}" = "" ] || [ $(git -C "${kernel_repo}" diff "${prev}" ${tag} -- "${path_inside}" | wc -l) -ne 0 ]; then
			gitcopy "${kernel_repo}" "${tag}" "${path_inside}" "${write_to}"
			cp -r "${write_to}/${tag}" "${write_to}/${tag}_patched"
		fi
	fi

	prev_version="${version}"
	prev="${tag}"
done
