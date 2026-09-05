#!/usr/bin/bash

# parameter:
# identical to git
# BUT:
# first HAS TO BE -C
# second the path to the directory

if [ "$1" != "-C" ]; then
	echo "$(basename "$0"): -C required as first parameter" >&2
	exit 1
fi
shift

dir="$1"
shift

if [ ! -d "${dir}/.git" ]; then
	echo "${dir} is no git repo" >&2
	exit 1
fi

owner=$(stat -c %U "${dir}/.git")
if [ "$(whoami)" = "${owner}" ]; then
	git -C "$dir" $*
else
	/usr/bin/su -l ${owner} -c "git -C \"${dir}\" $*"
fi

exit $?
