# alx-wol - atheros alx driver wol patch dkms

When using the Atheros alx driver on Ubuntu 20.04 the Wake On Lan
feature is functional as long as a kernel 5.14 is used.  
When switching to kernel 5.15 or newer the wol functionality is not
available anymore. Also using a newer Ubuntu version don't contain a
functional WOL with that ethernet interface.

This package adds the support for wol again as dkms package.

## * news *

Since Version 2.1.1 a first try of support for Proxmox is added.
There are some issues with the Proxmox system. On Debian and Ubuntu
when installing dkms the package `build-essential` gets installed.
This package installs the required linux headers, too.
On Proxmox Virtual Environment V8.2 this is not the case.
At least the headers for the currently running kernel are not installed.

If you want to use alx-wol on Proxmox please install the package
`proxmox-default-headers` and execute a reboot before doing the
alx-wol installation.

Since version 2.1 alx-wol is prepared for an easy adaption to other 
distributions than Ubuntu.  
First implemented is Debian.

Since version 2.0 of alx-wol this can not only be used to get alx
driver with wake on lan working.

Now this can be used for any kernel module which shall be patched
based on the original kernel sources. This system analyses the kernel
which shal be installed, detects its version and the compiler used. The
information about the kernel version is used to fetch the original
sources from kernel.org. A config file tells the system which patch to
use with which kernel version. The sources are patched. The system tries
to find the optimal compiler for the module and builds with it. After
that the initramf is updated to provide the new kernel module.

## Where it comes from

I was using an Ubuntu 20.04 on a home server containing the Atheros
ethernet chip. I configured it for Wake On Lan a long time ago and with
one ubuntu update the functionality was gone.

This was the change from kernel v5.14 to kernel v5.15.

That problem lead to the motivation to bring wol to life again. I
checked the basis where wol was removed from the alx driver on
kernel.org and created a patch to bring it in again.

With the next kernel update of Ubuntu I decided to get the compilation
of the module done automatically. Here my journey into dkms started.

Now I released version 2.0 of alx-wol.

And to be honest: this is more than alx driver with wake on lan. This
version is a framework for creating kernel modules based on original
kernel sources. It automatically detects the kernel version and the
compiler used for the kernel. Then it downloads the original kernel
sources, applies configurable patches and builds. And last but not
least it takes care to bring the module into the initramfs.

The alx-wol can be seen as one example for that mechanism. There are
two more examples which can be found in 'other_examples'.

## Compatibility

alx-wol has been tested on Ubuntu 22.04, 23.10 and 24.04. With regular 
kernel updates delieverd by Ubuntu the system works pretty nice. Also 
the kernels which can be downloaded from
[Mainline Kernel PPA](https://kernel.ubuntu.com/~kernel-ppa/mainline/)
work fine.

A short test has been executed on Debian 12 "bookworm".

Now another short test has been done on Proxmox Virtual Environment
V8.2. Please be careful with the linux header installation. I can't say
if these are always done during installation of a new kernel. If not
the alx build will fail and you don't have wake on lan.

In case of self compiled kernels one has to take care that the version
strings follow one of the Ubuntu ways.

If you want to use newer mainline kernels you can download and install
them. But you have to keep in mind that Ubuntu changes the environment
for building these kernels. So it can happen that a precompiled kernel
package leads to issues of alx-wol - which not neccesarily is based on
the alx-wol mechanism.

That was the case with kernel versions 6.4.13 and newer. Here Ubuntu
used a newer version of libc which wasn't compatible to the previous
one. It was not possible to install these mainline kernel packages
without additional big changes in the system. But as these packages
can't be installed the dkms mechanisms of alx-wol are not triggered.
It is NOT an issue of alx-wol.

With newer updates even Ubuntu 22.04 was switched to kernel 6.5. Here
of course also alx-wol works fine.

With Ubuntu 23.10 Ubuntu introduced a change in update-initramfs.
Getting that full functional was the kickoff for creating the generic
kernel module patch system as it is here.

In general: Ubuntu 22.04, 22.10 and 23.04 are supported.
Kernel versions v5.15.50 and newer are supported.  
But not all of the Ubuntu Mainline kernel packages are installable.

## How to use it

- clone the git repository
- cd into alx-wol
- execute *as root* **./install.sh**  
  you may use **sudo** for the execution

The script will check if there's already an old version of this dkms.  
If yes this can be deinstalled.

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
available after the next reboot. If the kernel is changed to a
different version the reboot should be done soon.

## Ho to remove it

Calling the script `remove.sh` will remove all installed versions of
this package from dkms. Only the installed data will be removed, the
sources are not removed with the script.

Only versions which have been successfully installed are removed.
In the case that there are artifacts from older versions these have to
be removed manually.

To check if there are remaining artefacts call

`dkms status`

If there are packages with the matching name but not 'installed' at the
end of the line there are some artifacts which should be removed. To do
so use

`sudo rm -rf /var/lib/dkms/<package_name>/<package_version>`

If you also want to remove the original sources use

`sudo rm -rf /usr/src/<package_name>-<package_version>`

**Caution!** There is a minus between the package name and the version,
NOT a slash as in the previous command!

## Issues found on Ubuntu

This is a list of issues found in the Ubuntu world leading to large
effort in alx-wol:

- different compilers used  
  there have been kernels which required a newer compiler than the one
  which was installed  
  Solution: since alx-wol version 2.0 the system tries to find the
  optimum compiler automatically
- changes in dkms system  
  a newer dkms system doesn't detect differences in modules if the
  value of **MODULE_VERSION** doesn't differ  
  In case of alx it's even one step worse:  
  these sources don't contain that define  
  Solution:
  MODULE_VERSION is automatically patched and now contains a time stamp
- changes in dkms system  
  when starting this project Ubuntus dkms system supported the feature
  **REMAKE_INITRD**  
  Since a newer version of Ubuntu the dkms reported this as depricated  
  Solution:
  own scripting around initramfs handling
- different libc versions used  
  Starting with a kernel 6.4.something in the kernel ppa Ubuntu used a
  newer version of glibc to build the kernel  
  No solution for alx-wol - but the whole kernel can't be used on older
  Ubuntu systems  
  Solution is to use the regular updates for these systems, not the PPA
  kernels
- changes in initramfs handling  
  since Ubuntu 23.04 Ubuntu changes to a new update-initramfs mechanism  
  With this mechanism no dkms build module is installed in the initramfs
  anymore  
  Solution: since version 2.0 there is an additional hook for
  mkinitramfs  
  This hook installs **all** dkms build modules into the initramfs

## issue found in Debian

When installing the required kernel header the script `extract-vmlinux`
of the kernel sources is not installed. Because of that the script 
`extract_kversion_string.sh` first checks if the script is available 
and if not downloads and uses the one matching the currently running 
kernel.

# documentation for the generic dkms mechanism

The new generic kernel module patch mechanism is explained
[here](kernelpatching.md)

# History

**Version 2.1**

Introduction of mechanism to integrate other distributions than Ubuntu.
First other distribution implemented: Debian.

**Version 2.0**

Introduction of generic kernel module patching mechanism  
The patch mechanism supports falling back to defined patches  
As long as these apply there should be no need to change anything in
alx-wol  
First version which is able to handle update-initramfs on Ubuntu 23.10  
Added documentation for the generic mechanism

**Version 1.5**

Introduced support for Kernel 6.5  
Because of a change in update-initramfs this doesn't work on Ubuntu
23.10

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
The author doesn't take any responsibility for any kind of malfunction
or data loss on your system.
