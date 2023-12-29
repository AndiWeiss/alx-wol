#!/bin/sh

echo "XXXXXXXXXXXXXX $(basename "$0") started >$*< XXXXXXXXXXXXXX"
i="$(grep '^[[:space:]]*BUILT_MODULE_NAME[[:space:]]*\[[0-9]\{1,\}\][[:space:]]*=' dkms.conf)"
all_names="$(echo "$i" | sed -n 's|^[^"]*"\([^"]*\).*$|\1|gp')"
echo "all_names: >>>>$all_names<<<<"

cur=0
end=$(echo "$all_names" | wc -l)
while [ $cur -lt $end ];
do
	cur=$(expr $cur + 1)
	name="$(echo "$all_names" | sed -n "${cur}p")"
	echo "test: >$name<"
done

echo "XXXXXXXXXXXXXX $(basename "$0") exit XXXXXXXXXXXXXX"
