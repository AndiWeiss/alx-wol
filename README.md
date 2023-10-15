# alx-wol - atheros alx driver wol patch dkms

When using the Atheros alx driver on Ubuntu 20.04 the Wake On Lan
feature is functional as long as a kernel 5.14 is used.  
When switching to kernel 5.15 or newer the wol functionality is not
available anymore. Also using a newer Ubuntu version doesn't lead to a
functional WOL with that ethernet interface.

This package adds the support for wol again as dkms package.

## Where does it come from

I was using an Ubuntu 20.04 on a home server containing the Atheros
ethernet chip. I configured it for Wake On Lan a long time ago and with
one update the functionality was gone.

This was the change from kernel v5.14 to kernel v5.15.

This lead to the motivation to bring wol to life again. I checked the
basis where wol was removed from the alx driver on kernel.org and
created a patch to bring it in again.

With the next kernel update of Ubuntu I decided to get the compilation
of th emodule done automatically. Here my journey into dkms started.

With this version (1.5) of alx-wol I hade to create fixes for several
issues on Ubuntu side. The latest thing I found is not yet fixed, so
alx-wol 1.5 is not usable on Ubuntu 23.10 up to now. But I'll do my
very best.

## Compatibility

alx-wol has been tested on Ubuntu 22.04 and 23.04. With regular kernel
updates delieverd by Ubuntu the system works pretty nice.

If you want to use newer mainline kernels you can download and install
them. But you hae to keep in mind that Ubuntu changes the environment
for building these kernels. So it can happen that a precompiled kernel
package leads to issues of alx-wol.

That was the case with kernel versions 6.4.13 and newer. Here Ubuntu
used a newer version of libc which wasn't compatible to the previous
one. It was not possible to install these mainline kernel packages
without additional big changes in the system. But as these packages
can't be installed the dkms mechanisms of alx-wol are not triggered.
It is NOT a problem of alx-wol.

With Ubuntu 23.10 Ubuntu introduced a change in update-initramfs.
With this Ubuntu version the alx-wol system creates a functional
alx module, but this module is not intgrated into the initramfs.
So after reboot the original Ubuntu version of the alx module is used
again and the wol functionality is gone again. Again this is an issue
of Ubuntu, not of alx-wol. Nevertheless I'll try to create a fic for
that.

In general: Ubuntu 22.04, 22.10 and 23.04 are supported.
Kernel versions v5.15.50 and newer are supported.  
But not all of the Ubuntu Mainline kernel packages are installable.

Meanwhile it seems that Ubuntu took the mainline kernel download
offline. Some time ago there was the page
[Mainline Kernel PPA](https://kernel.ubuntu.com/~kernel-ppa/mainline/)
but it seems to be not available anymore. So currently I don't know
where to get newer test kernels without compiling them by myself.

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

## Issues found on Ubuntu

This is a list of issues found in the Ubuntu world leading to large
effort in alx-wol:

- different compilers  
  Somewhere Ubuntu switched from gcc-12 to gcc-13  
  created a workaround in alx-wol
- dkms system of Ubuntu 23.04 doesn't see a difference between the
  preinstalled module and the new compiled one.  
  Reason: alx doesn't contain a MODULE_VERSION entry.  
  Introduced that including build date and time
- Ubuntu uses libc 2.38 while the regular systems still contain 2.37  
  No solution for alx-wol
- Ubuntu 23.10 contains a change in update-initramfs which doesn't add
  dkms compiled modules to the initramfs  
  Up to now no solution found for alx-wol  
  My assumption: any module which is compiled with dkms is harmed here

# History

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
The author doesn't take any responsibility for any kind of malfunction or data loss on your system.
