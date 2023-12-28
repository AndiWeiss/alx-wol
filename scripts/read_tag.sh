#!/bin/sh
#!/bin/sh

req_version="$1"
tag="$2"
single="$3"
config_file="$4"

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
end=-1
while read line;
do
	cur=$(expr $cur + 1)
	i=$(echo "${line}" | grep -c '^[[:space:]]*\[kernel[[:space:]]')
	if [ $i -eq 1 ];
	then
		if [ $matching -eq 0 ];
		then
			if [ "$cur_version" != "" ];
			then
				end=$cur
			fi
			chk_version=$(echo "${line}" | sed -n 's|^[[:space:]]*\[kernel[[:space:]]*\([[:digit:]]\{1,\}\.[[:digit:]]\{1,\}\.[[:digit:]]\{1,\}\)[[:space:]]*\][[:space:]]*$|\1|p')
			res=$(compare "${chk_version}" "${req_version}")
			if [ $res -eq 0 ];
			then
				prev_version="${chk_version}"
				start=$cur
				cur_version="${chk_version}"
				kerneldir=""
				scandir=0
				matching=1
			elif [ $res -lt 0 ]
			then
				res=$(compare "${prev_version}" "${chk_version}")
				if [ $res -lt 0 ];
				then
					prev_version="${chk_version}"
					start=$cur
					cur_version="${chk_version}"
					kerneldir=""
					scandir=0
				else
					cur_version=""
				fi
			else
				cur_version=""
			fi
		else
			end=$cur
			break
		fi
	fi
done < "${config_file}"
if [ $end -lt 0 ];
then
	end=$cur
fi

cur=0
found=0
while read line;
do
	cur=$(expr $cur + 1)

	if [ $cur -le $start ]
	then
		continue
	fi

	if [ $cur -gt $end ]
	then
		break
	fi

	i=$(echo "$line" | grep -c "\[.*\]")
	if [ $i -eq 1 ];
	then
		if [ $found -ne 0 ];
		then
			break;
		else
			i=$(echo "$line" | grep -c "^[[:space:]]*\[[[:space:]]*${tag}[[:space:]]*\]")
			if [ $i -eq 1 ];
			then
				found=1
			fi
			continue
		fi
	fi

	if [ $found -ne 0 ];
	then
		i=$(echo "$line" | grep -c '^[[:space:]]*#')
		if [ $i -eq 0 ];
		then
			line="$(echo "$line")"
			if [ "$line" != "" ];
			then
				echo "$line"
				if [ $single -ne 0 ];
				then
					break
				fi
			fi
		fi
	fi
done < "${config_file}"
