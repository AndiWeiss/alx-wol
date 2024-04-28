# Generic kernel module patching

This is the documentation for the generic kernel module patching
mechanism created for the alx-wol package. It can be used for any
kernel module patch which shall be applied automatically on kernel
installation with dkms. It will always fetch the original sources from
kernel.org - no need to provide a specific version. There's also a
possibility to provide patches based on the kernel version.

## How to use the generic kernel patching mechanism

The complete system is defined with three files:

- dkms.conf
- Makefile
- sources.txt

### dkms.conf configuration

In this file the configuration for the underlying dkms has to be done.

**PACKAGE_NAME** has to be filled with the name to use in dkms.

This name has to be used for installation or removal of the dkms package.

**PACKAGE_VERSION** is the version number of the dkms package.

This is NOT related to the kernel version. Change this value if you
want to provide a newer configuration for the patch mechanism, e.g. a
new patch for an up to now not supported kernel.

**BUILT_MODULE_NAME[0]** is the name of the module to build.

Dependent on how the kernel is configured the module can have different
filename extentions like .ko or .ko.xz or other compression extentions.
The file extention must not be mentioned here.

**BUILT_MODULE_LOCATION[0]** is the path where the module is located
after the build process.

The path to give depends on the sources which are handled. The alx
driver for example fetches a complete directory 'alx' from kernel.org,
so the module is created in that directory.

**DEST_MODULE_NAME[0]** should be the same as BUILT_MODULE_NAME[0].

**DEST_MODULE_LOCATION[0]** is the location where the module shall be
deployed.

This path is relative to the original module path. In case of Ubuntu
based systems keep /updates. A change of this value requires changes in
the scripting!

Do not change any other line in dkms.conf.

### Makefile configuration

Adapt this makefile to your needs. It is handled by the kernel build
system, so it should follow the kbuild recommendations.

### sources.txt

This file contains the information which sources to fetch for which
kernel version and the required patches for them.

#### kernel version definition

example:

**`[kernel 5.15.1]`**

all lines until the next line starting with `[kernel` are used for this
kernel version and higher versions. Higher versions means until the next
higher defined kernel version.

Valid token for each defined kernel version:

**`[kerneldir]`**

defines the path inside the kernel repository. All files and directories
defined in `[files]` are taken relative to this path.

**`[files]`**

a list of files and directories located in the kernel directory defined
by `[kerneldir]`. One entry per line, each one may be a file or a
directory.

**`[patches]`**

a list of patches to apply. One patch per line, the patches are aplied
in the order they are mentioned. The path is relative to the main
directory.

**`[versionpatch]`**

Here one file can be menitioned which is expected to contain the define
`MODULE_VERSION`. If this is mentioned the `MODULE_VERSION` is patched
to get a unique module version for each compilation process. If the
define is not in the file it will be added and contain a time stamp.
Otherwise a time stamp is added behind the original content, separated
by an underscore.

# internals

The following explains in detail how the mechanism works.
Each script is explained.

## generic flow

If a new kernel gets installed in a system equipped with dkms each
dkms based module gets compiled.
The file `dkms.conf` explains required details to dkms.
But `dkms.conf` is not a simple configuration file, it is 'sourced' by
the dkms mechanism and therefore it is a script.

Everything explained in the dkms documentation only explains the
variables which can be set in the file. But additonally one can add
regular script handling here.

Before anything else is done the scripting inside dkms.conf is
processed. This is used to extract required information out of the
kernel to install. Each kernel source contains a script to extract the
vmlinux out of the prepared kernel file. this is used to get the
uncompressed linux kernel. The uncompressed kernel contains a lot of
strings - one of them contains the kernel version.

The script `extract_kversion_string.sh` first extracts the kernel and
then the version string out of the uncompressed kernel. Since alx-wol 
version 2.1 it first checks if the required kernel script `extract-vmlinux` 
is available in the kernel headers.  
If it is not available it is fetched from kernel.org based on the
version of the currently running kernel.

The script `extract_kversion.sh` uses the kernel version string to
get the kernel version. This is a wrapper for distribution dependent
scripts. Currently there are scripts for Ubuntu and Debian.

The script `Ubuntu.sh` is able to handle two different version string 
formats found in Ubuntu kernels: the one of a regular update and the 
one of mainline ppa kernels. This script expects two parameters. The
First parameter is the file containing the complete kernel version 
string. The second parameter has to be either kernel or gcc to tell
what to extract.

Regular Ubuntu kernels contain a string like this (in one line):  
`Linux version 6.5.0-14-generic (buildd@lcy02-amd64-110)`  
`(x86_64-linux-gnu-gcc-12 (Ubuntu 12.3.0-1ubuntu1~22.04) 12.3.0, GNU ld (GNU Binutils for Ubuntu) 2.38)`  
`#14~22.04.1-Ubuntu SMP PREEMPT_DYNAMIC Mon Nov 20 18:15:30 UTC 2`  
`(Ubuntu 6.5.0-14.14~22.04.1-generic 6.5.3)`

Ubuntu Mainline PPA kernel contain:  
`Linux version 6.6.5-060605-generic (kernel@kathleen)`  
`(x86_64-linux-gnu-gcc-13 (Ubuntu 13.2.0-7ubuntu1) 13.2.0, GNU ld (GNU Binutils for Ubuntu) 2.41)`  
`#202312080833 SMP PREEMPT_DYNAMIC Fri Dec  8 08:45:34 UTC 2023`

Having that in mind leads to:

- first check if there is a three number version followed by a bracket
  at the end of the line  
  If yes and major plus minor fits the name of the kernel to install:  
  take this three number version as kernel version
- if this is not the case check for a three number version behind
  `Linux version`  
  If yes and major plus minor fits the name of the kernel to install:  
  take that one
- if none of these possibilities was found we can't proceed

The script `Debian.sh` is able to handle two different version string 
formats found in Ubuntu kernels: the one of a regular update and the 
one of mainline ppa kernels. This script expects two parameters. The
First parameter is the file containing the complete kernel version 
string. The second parameter has to be either kernel or gcc to tell
what to extract.

Debian kernel string example:  
`Linux version 6.1.0-18-amd64 (debian-kernel@lists.debian.org)`  
`(gcc-12 (Debian 12.2.0-14) 12.2.2, GNU ld (GNU Binutils for Debian) 2.40)`  
`# SMP PREEMPT_DYNAMIC Debian 6.1.76-1 (2024-02-01)`

If none of these mechanisms fulfills the requirements one can add 
another custom kernel version into `extract_kversion.sh` and create an
additonal extraction script.

The same version string is used to get the gcc version used to compile
the kernel. This is done in `gcc_used.sh`. That script is another 
wrapper around the extraction scripts. Extracting the gcc version used
is identical for Ubuntu and Debian.

This script searches mainly for a three digit version followed by a
comma.  
If this is found it is expected to be the used gcc version number.

After detecting a gcc version number dkms.conf searches for installed
gcc versions in the system.  
To do so it checks for executables starting with the architecture (in
the mentioned examples `x86_64`) followed by characters containing
`gcc`.  
If such files are found as executables they are called with parameter
`--version`.

The optimum one is returned as compiler to use.

If all of these steps succeeded the required information for a best
possible patch and compilation is available.

Now dkms continues with the information out of `dkms.conf`.

The script defined in `PRE_BUILD` is executed.  
That's `fetchsources.sh` which is responsible to use the kernel version
to fetch the configured sources from `kernel.org`.  
After fetching all sources the configured patches are applied.

The dkms system calls `make` as next step.

After `make` the script defined in `POST_INSTALL` is executed.  
That script, `handleinitrd.sh`, takes care that the dkms build modules
are written into the initramfs.

In the case that the patched module shall be removed the script defined
in `POST_REMOVE` is called.  
Here the same script `handleinitrd.sh` is used. It gets the information
if the modules have to be installed or removed.

The mkinitramfs provided with Ubuntu systems starting with 23.10
require an additional hook to get the dkms compiled modules into the
initramfs.  
This module is provided as `dkms-adder` together with this package.  
During installation it is written to `/etc/initramfs-tools/hooks/`.
At this location it is automatically executed by `mkinitramfs` and adds
all dkms build modules to the initramfs.

All explained scripts are equipped with comments explaining what
happens where.  
So if you are interested in details: Use the force, read the source.
