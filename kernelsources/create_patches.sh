#!/bin/bash

# This is only for creation of patches
# it's not required for alx-wol, only a tool for fast patch creation

for d in $(ls -d v* | grep -v '_patched$'); do
	diff -upr $d ${d}_patched > ../patches/alx-wol_$d.patch
	chmod 640 ../patches/alx-wol_$d.patch
done
