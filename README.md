# alx-wol - atheros alx driver wol patch dkms

When using the Atheros alx driver on Ubuntu 20.04 the Wake On Lan
feature is functional as long as a kernel 5.14 is used.  
When switching to kernel 5.15 the wol functionality is not available
anymore.

This package adds the support for wol again as dkms package.

## Where does it come from

This dkms bases on the currently most actual kernel sources, the v6.0.3.  
These alx sources are fetched during installation.  
I did a comparison beginning with kernel v5.15.50 until v6.0.x and
found only minor differences in the alx driver.
All of these kernel versions can use the same sources and the same
patch to get the alx running with wake on lan.
So I decided to use the sources of the kernel 6.0.3 for all of these
versions. To enable the wake on lan feature again I created the patch
**patches/0000-alx-wol-v6.0.3.patch**.

In the next step I added the support for kernel 6.1 and 6.2. Here I
found that there was an interface change in the network system.
The parameter weight of function netif_napi_add has been dropped
starting with kernel 6.1. This leads to the need of different sources
for kernels up to 6.0 and kernels starting with 6.1.

Luckily the patch for the 6.0.3 applies without any issue on the new
6.1 and 6.2 atheros driver. Because of that I only had to take care to
use different sources for different kernel versions.

When checking the build for the 6.3 kernel I found that the 6.0.3 patch
doesn't apply on the 6.3 alx sources.  
I had to create a new patch - **patches/0001-alx-wol-v6.3.patch**

Previously I fetched the kernel source during the initialization script.

With the current version the sources are fetched during dkms run as
soon as the kernel version or major revision changes.

## How to use it

- clone the git repository
- cd into alx-wol
- execute *as root* **./install_alx-wol.sh**  
  you may use **sudo** for the execution

The script will check if there's already an old version of this dkms.  
If yes this will be deinstalled.

*I didn't test the deinstallation very deeply. In the case that the
automatic deinstallation fails please use  
`sudo dkms remove alx-wol/<version_to_remove>`  
to get back to the original alx driver and then du the installation
again.*

After that the new version is installed.  
To do so the alx sources are fetched from kernel.org,  
then the dkms mechanism is called to install the package.

As last action the script checks if the running kernel uses the original
version of the alx driver. If yes it is replaced by the new compiled
alx-wol module. The initrd is updated so that the wol feature is still
available after the next reboot. If the kernel is changed to a different
major version the reeboot should be done soon.

## Problems with the previous versions of alx-wol

During implementation of the changes for linux kernel 6.3 I faced that
my previous versions of this package didn't work properly.

In my configuration everything looked like it worked fine, but when I
started a new test marathon I found id didn't work at all.  
Functional wol on my system was just good luck.

Now I did a real testing and bug fixing marathon. I tested the
functionality:

* on Xubuntu 22.04
  - with kernel 5.15
  - with kernel 5.19
  - with kernel 6.0
  - with kernel 6.1
  - with kernel 6.2
  - with kernel 6.3
  - with kernel 6.4

* on Xubuntu 23.04
  - with kernel 6.2
  - with kernel 6.3

In any case 'with kernel x.y' means with several versions of that
kernel (e.g. 6.2.1, 6.2.2, 6.2.3 and so on).

## Problems found during testing

The change to kernel 6.3 together with the new ubuntu lead to several
problems which I had to solve.

The first part was already solved - but sadly not full functional - in
version 1.2. That was the requirement to use different sources for
different kernel versions.

With kernel 6.3 the next point was to be able to handle different
patches on different sources.

What I didn't find during testing of version 1.2:  
For kernel 6.0 the gcc has to be a gcc-12. The new kernel uses a gcc
feature which was introduced with gcc-12.  
Because of that version 1.3 checks the compiler version and requests
gcc-12 in the case that gcc is a lower version.

After having that all running on Xubuntu 22.04 I decided to test it on
Xubuntu 23.04, too. Here I struggled with the next issue.

On Xubuntu 23.04 dkms compiled the patched sources and then complained
that the new compiled version is identical to the original one and
therefore dropped the new compiled module.

After a deep dive into the dkms scripting I found that the version of
dkms used in Xubuntu 23.04 uses modinfo to read the module version of
the currently used module and the new compiled one. If these two
versions are the same it denies the usage of the new one.

Taking a look into the original alx sources I found that there is no
`MODULE_VERSION` defined. It does simply not exist. And because of that
the versions of both modules are empty strings - so they are equal.
As the dkms version on Xubuntu doesn't do an additional check the new
modules are never used.  
Newer versions of dkms have this issue fixed - if they find the same
version they do a binary comparison of the modules.

I fixed that by introducing a new patch mechanism which is executed
with each build. This patch mechanism checks all source files for the
usage of the `MODULE_VERSION` macro. If none of the sources contains
that macro one line with its usage is pasted at the end of `main.c`.
The version is set to: `YYYY-MM-DD_hh:mm.ss`  
YYYY is the current year, MM, the current month, DD the current day.  
hh is the current hour (in 24h format), mm the current minute and ss the
current second.

If a line with that macro is found it is checked if that line contains
my tag. If not it is just added to the original line.

If my tag is already in it is exchanged by the timestamp of the
compilation time.

Doing so leads to a different version with each build.

Now I thought 'that's it' - but still there was another issue.

Previously I used the `REMAKE_INITRD` feature of dkms. This feature is
not supported anymore in newer dkms versions. So again I had to find a
solution.

I introduced the script `HandleInitrd` which takes care for the correct
usage. This script is called both during dkms install and dkms remove.
It takes care to do the initrd update as required. Additionally it also
checks during installation if the active module is the original kernel
module or not. If the active module is the original module it uses
`rmmod` to remove it and `insmod` to install the fresh compiled one.
With this the wake on lan feature gets active during installation and
not only after the next reboot. During `dkms remove` that script checks
again which module is active. Now it does it the other way round: if the
active module is not the original one it deinstalls the active module
and installs the original again.

# History

**Version 1.4.1**

Workaround for missing dependency in 6.4.6 kernel package in ubuntu  
Package expects to find gcc-13 but there is no dependency

**Version 1.4**

bugfix on installation of newer version of alx-wol  
intruduction of support for kernel 6.4

**Version 1.3**

First full functional version  
Supports Kernel 5.15 - 5.19, 6.0, 6.1, 6.2 and 6.3  
Deinstallation of previous versions doesn't work correctly.  

# Disclaimer

This package is provides AS IS.  
**Use it on your own risk.**  
The author doesn't take any responsibility for any kind of malfunction or data loss on your system.
