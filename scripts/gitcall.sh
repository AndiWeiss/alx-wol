#!/usr/bin/bash

# parameter:
# identical to git
# BUT:
# first HAS TO BE -C
# second the path to the directory

llr_file="$(dirname $0)/local-linux-repo"

if [ "$1" != "-C" ] && [ "$1" != "get_dir" ] && [ "$1" != "inval" ]; then
	echo "$(basename "$0"): -C, get_dir or inval required as first parameter" >&2
	exit 1
fi

if [ "$1" = "inval" ]; then
	rm -f "${llr_file}"
	exit 0
fi

get_local_linux_repo ()
{
	echo "$(grep 'local-linux-repo=' "${llr_file}"|sed 's|^local-linux-repo=||')"
}

if [ "$1" = "get_dir" ]; then
	# check if local git repo is available
	if [ -f "${llr_file}" ]; then
		get_local_linux_repo;
		exit 0
	else
		exit 1
	fi
fi

dir="$(realpath $2)"

call_git_with_user ()
{
	if [ "$3" = "fetch" ]; then
		current_time=$(/usr/bin/date +%s)
		prev_time=$(/usr/bin/stat -c %Y "${dir}/.git/FETCH_HEAD")

		diff_time=$(/usr/bin/expr ${current_time} - ${prev_time})

		# seconds for one day: 60 * 60 * 24 = 86400
		if [ $diff_time -le 86400 ]; then
			exit 0
		fi
	fi

	owner=$(stat -c %U "${dir}")
	if [ "$(whoami)" = "${owner}" ]; then
		/usr/bin/git $*
	else
		if [ "$(whoami)" = "root" ]; then
			/usr/bin/su -l ${owner} -c "git $*"
		else
			return 1
		fi
	fi

	return $?
}

if [ ! -f "${llr_file}" ]; then
	call_git_with_user "$1" "$2" status
	if [ $? != 0 ]; then
		echo "$(basename $0): ${dir} seems to be no git repo" >&2
		exit 1
	fi

	if [ ! -f "${dir}/README" ] ||
	[ "$(grep -n '^Linux kernel$' "${dir}/README")" != "1:Linux kernel" ]; then
		echo "${dir} seems to be no kernel"
		exit 1
	fi

	echo "local-linux-repo=${dir}" > "${llr_file}"
else
	dir="$(get_local_linux_repo)"
fi

set -- "$1" "${dir}" "${@:3}"

call_git_with_user $*
exit $?
