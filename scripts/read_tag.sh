#!/bin/sh

# reads tags out of the configuration file
# first parameter: kernel version the tag has to be exported for
# second parameter: The tag to seach for
# third parameter: 1 if the tag has to have a single entry
#                  0 if it may contain multiple entries
# fourth parameter: the config file to scan
req_version="$1"
tag="$2"
single="$3"
config_file="$4"

# conpare two versions
# each version has to be number.number.number
# result:
# -1 if first version is lower than second
# 0 if both versions are equal
# 1 if first version is larger than second
compare ()
{
	first_major=$(echo $1 | sed -n 's|^\([[:digit:]]\{1,\}\)\.[[:digit:]]\{1,\}\.[[:digit:]]\{1,\}$|\1|p')
	first_minor=$(echo $1 | sed -n 's|^[[:digit:]]\{1,\}\.\([[:digit:]]\{1,\}\)\.[[:digit:]]\{1,\}$|\1|p')
	first_patch=$(echo $1 | sed -n 's|^[[:digit:]]\{1,\}\.[[:digit:]]\{1,\}\.\([[:digit:]]\{1,\}\)$|\1|p')

	second_major=$(echo $2 | sed -n 's|^\([[:digit:]]\{1,\}\)\.[[:digit:]]\{1,\}\.[[:digit:]]\{1,\}$|\1|p')
	second_minor=$(echo $2 | sed -n 's|^[[:digit:]]\{1,\}\.\([[:digit:]]\{1,\}\)\.[[:digit:]]\{1,\}$|\1|p')
	second_patch=$(echo $2 | sed -n 's|^[[:digit:]]\{1,\}\.[[:digit:]]\{1,\}\.\([[:digit:]]\{1,\}\)$|\1|p')

	first=$(printf "%04d%04d%04d\n" $first_major $first_minor $first_patch)
	second=$(printf "%04d%04d%04d\n" $second_major $second_minor $second_patch)

	if [ $first -lt $second ];
	then
		echo "-1"
	elif [ $first -eq $second ];
	then
		echo "0"
	else
		echo "1"
	fi
}

prev_version=""
kerneldir=""
scandir=0

cur=0
matching=0
start=1
end=-1
# walk through the config file
# and search for the area where the tag has to be taken from
while read line;
do
	cur=$(expr $cur + 1)
	# search for lines containing the kernel version
	i=$(echo "${line}" | grep -c '^[[:space:]]*\[kernel[[:space:]]')
	if [ $i -eq 1 ];
	then
		# found a kernel version line
		if [ $matching -eq 0 ];
		then
			# currently not matching
			if [ "$cur_version" != "" ];
			then
				# found next kernel version line
				# --> save this as last line
				end=$cur
			fi
			# extract kernel version
			# this line extracts a version with three numbers
			chk_version=$(echo "${line}" | sed -n 's|^[[:space:]]*\[kernel[[:space:]]*\([[:digit:]]\{1,\}\.[[:digit:]]\{1,\}\.[[:digit:]]\{1,\}\)[[:space:]]*\][[:space:]]*$|\1|p')
			if [ "$chk_version" = "" ];
			then
				# this line extracts a version with two numbers
				chk_version=$(echo "${line}" | sed -n 's|^[[:space:]]*\[kernel[[:space:]]*\([[:digit:]]\{1,\}\.[[:digit:]]\{1,\}\)[[:space:]]*\][[:space:]]*$|\1.0|p')
			fi
			# compare against the requested version
			res=$(compare "${chk_version}" "${req_version}")
			if [ $res -eq 0 ];
			then
				# version matches!
				# save this as previous version
				prev_version="${chk_version}"
				# save the starting line
				start=$cur
				# save this as current version
				cur_version="${chk_version}"
				# init some variables
				kerneldir=""
				scandir=0
				matching=1
			elif [ $res -lt 0 ]
			then
				# it's lower than the requestes
				# compare against the previously scanned version
				res=$(compare "${prev_version}" "${chk_version}")
				if [ $res -lt 0 ];
				then
					# previously scanned version is lower
					# --> use the current for scan
					prev_version="${chk_version}"
					start=$cur
					cur_version="${chk_version}"
					kerneldir=""
					scandir=0
				else
					# otherwise drop the current version
					cur_version=""
				fi
			else
				# the current version is larger than the requested
				# --> just continue searching
				cur_version=""
			fi
		else
			# we had a matching version before and found the
			# next kernel version line
			# --> save the end line
			end=$cur
			break
		fi
	fi
done < "${config_file}"
if [ $end -lt 0 ] || [ $end -eq $start ];
then
	# for the last version in the config file
	end=$cur
fi

# now extract the tag between $start and $end
cur=0
found=0
while read line;
do
	cur=$(expr $cur + 1)

	if [ $cur -le $start ]
	then
		# before start, read next line
		continue
	fi

	if [ $cur -gt $end ]
	then
		# behind end, stop search
		break
	fi

	# check for a line containing '[...]'
	i=$(echo "$line" | grep -c "\[.*\]")
	if [ $i -eq 1 ];
	then
		# matches
		if [ $found -ne 0 ];
		then
			# in the case we where reading the searched value
			# simply stop reading, we reached the next tag
			break;
		else
			# tag wasn't found until now
			# check if the tag is in
			i=$(echo "$line" | grep -c "^[[:space:]]*\[[[:space:]]*${tag}[[:space:]]*\]")
			if [ $i -eq 1 ];
			then
				# it is, mark for the next lines
				found=1
			fi
			# read next line
			continue
		fi
	fi

	# check for tag content
	if [ $found -ne 0 ];
	then
		# check for comment line
		i=$(echo "$line" | grep -c '^[[:space:]]*#')
		if [ $i -eq 0 ];
		then
			# not a comment
			line="$(echo "$line")"
			if [ "$line" != "" ];
			then
				# not an empty line,
				# print it
				echo "$line"
				if [ $single -ne 0 ];
				then
					# a single entry is requested
					# stop searching
					break
				fi
			fi
		fi
	fi
done < "${config_file}"
