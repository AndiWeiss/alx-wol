#!/usr/bin/env python3

# this script can be used to get all those directories out of the
# kernel sources, which either have the sublevel zero or contain
# cahnges to the previous kernel release

# Parameter:
# -k path to kernel sources
# -d path inside the kernel sources, which shall be checked
# -o where to store the sources

import sys
import os
import re
import shutil
from argparse import ArgumentParser

def fetch_source(kernel, dir, output, tag):
	if False == os.path.isdir(output + "/" + tag):
		src = kernel + "/" + dir
		dest = output + "/" + tag + "/"
		os.mkdir(output + "/" + tag)
		exit_code = os.system("git -C " + kernel + " checkout " + tag + " --quiet")
		print("copy " + tag + " to " + dest)
		exit_code = os.system("cp -pr " + src + " " + dest + " > /dev/null")

parser = ArgumentParser()

parser.add_argument("-k", "--kernel", dest="kernel", default=".")
parser.add_argument("-d", "--directory", dest="dir", default="")
parser.add_argument("-o", "--output", dest="output", default="")

args = parser.parse_args()

kernel=args.kernel
dir=args.dir
output=args.output

if output == "":
	sys.exit("No output directory given")

if dir == "":
	sys.exit("No directory given")

if False == os.path.isdir(output):
	sys.exit("Directory " + output + " doesn't exist")

exit_code = os.system("git -C " + kernel + " rev-parse 2> /dev/null > /dev/null")
if exit_code != 0:
	sys.exit("directory " + kernel + " is no git repository")

exit_code = os.system("git -C " + kernel + " diff --quiet")
if exit_code != 0:
	sys.exit("git repo " + kernel + " is dirty")

orig_kernel_hash = os.popen("git -C " + kernel + " rev-parse HEAD").read()
orig_kernel_hash = orig_kernel_hash[0:40]
if "" == orig_kernel_hash:
	sys.exit("didn't get current hash in " + kernel)

all_tags = os.popen("git -C " + kernel + " tag --list").read()

all_tags = re.split("\s", all_tags)

#initial_tags = []
versions = []
for tag in all_tags:
	sublevel = -1
	x = re.search("^v\d{1,}\.\d{1,}$", tag)
	if x:
#		initial_tags.append(tag)
		handle = 1
		sublevel = 0
	else:
		x = re.search("^v\d{1,}\.\d{1,}\.\d{1,}$", tag)
		if x:
#			initial_tags.append(tag)
			handle = 1
			sublevel = 1

	if 0 <= sublevel:
		version = re.sub("^v", "", tag)
		version = int(re.sub("\..*$", "", version))
		version = "{:04d}".format(version)
		patchlevel = re.sub("^v\d{1,}\.", "", tag)
		patchlevel = int(re.sub("\..*$", "", patchlevel))
		patchlevel = "{:04d}".format(patchlevel)
		if 0 != sublevel:
			sublevel = int(re.sub("^v\d{1,}\.\d{1,}\.", "", tag))

		sublevel = "{:04d}".format(sublevel)

		versions.append(version + "." + patchlevel + "." + sublevel)

versions.sort()
old_version = 0
old_patchlevel = 0
old_sublevel = 0
old_tag = ""
for tag in versions:
	version = int(tag[0:4])
	patchlevel = int(tag[5:9])
	if version < 5:
		continue
	if version == 5 and patchlevel < 15:
		continue

	sublevel = int(tag[10:15])

	if "" == old_tag or old_version != version or old_patchlevel != patchlevel:
		old_version = version
		old_patchlevel = patchlevel
		old_sublevel = sublevel
		if 0 == sublevel:
			old_tag = "v" + str(version) + "." + str(patchlevel)
		else:
			old_tag = "v" + str(version) + "." + str(patchlevel) + "." + str(sublevel)

		cmp_tag = old_tag
		fetch_source(kernel, dir, output, old_tag)
		continue

	if 0 == sublevel:
		new_tag = "v" + str(version) + "." + str(patchlevel)
	else:
		new_tag = "v" + str(version) + "." + str(patchlevel) + "." + str(sublevel)

	diff = os.popen("git -C " + kernel + " diff " + cmp_tag + " " + new_tag + " " + dir).read()
	if "" != diff:
		fetch_source(kernel, dir, output, new_tag)
		cmp_tag = new_tag

os.system("git -C " + kernel + " checkout " + orig_kernel_hash + " --quiet")
