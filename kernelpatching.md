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
deployed. This should be the path where the original module is located.

The dkms system on many distributions uses a hard coded value for
DEST_MODULE_LOCATION. Nevertheless the patch mechanism needs the original
path for a clean removal of the package.

Do not change any other line in dkms.conf.

### Makefile configuration

Adapt this makefile to your needs. It is handled by the kernel build
system, so it should follow the kbuild recommendations.

### sources.txt

This file contains the information which sources to fetch for which
kernel version and the required patches for them.

#### Kernel version definition

example:

**`[kernel 5.15]`**

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

# Internals

The following explains in detail how the mechanism works.
Each script is explained.

## Generic flow

If a new kernel gets installed in a system equipped with dkms each
dkms based module gets compiled.
The file `dkms.conf` explains required details to dkms.
But `dkms.conf` is not a simple configuration file, it is 'sourced' by
the dkms mechanism and therefore it is a script.

Everything explained in the dkms documentation only explains the
variables which can be set in the file. But additonally one can add
regular script handling here.

Before anything else is done the scripting inside dkms.conf is
processed. This is used to extract required information.

The kernel version can be detected by checking the Makefile belonging to the
linux headers for the three variables `VERSION`, `PATCHLEVEL` and `SUBLEVEL`.
Problem here may be that the file  
`/usr/src/$(uname -r)/Makefile`  
may not be the complete makefile of the kernel headers. In several distributions
this file only includes the 'real' makefile. Based on this finding the alx-wol
mechanism checks if the first file contains the variables and if not it checks
if another Makefile is include. If yes it checks that for the variables.

The compiler version used to compie the kernel can be found in the file  
``/usr/lib/modules/$(uname -r)/build/include/config/auto.conf``  
The tag ``CONFIG_CC_VERSION_TEXT`` contains the version string of the gcc.
Expectation is that the last part of this string is the gcc version number.

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
