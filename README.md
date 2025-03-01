# alx-wol - atheros alx driver wol patch dkms

When using the Atheros alx driver on Ubuntu 20.04 the Wake On Lan
feature is functional as long as a kernel 5.14 is used.  
When switching to kernel 5.15 or newer the wol functionality is not
available anymore. Also using a newer Ubuntu version don't contain a
functional WOL with that ethernet interface.

This package adds the support for wol again as dkms package.

## * news *

**Version 3.0 has been successfully tested on: Debian, Ubuntu, Proxmox, Fedora,
Arch and Suse!**

It is expected that the kernel got compiled with gcc.
As tool for initrd createion there has to be either mkinitcpio, update-initramfs
or dracut.

Please take care to check the requirements based on the explanations about usage
with different distributions.

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

Now I released version 3.0 of alx-wol.

And to be honest: this is much more than alx driver with wake on lan.
This version is a framework for creating kernel modules based on original
kernel sources. It automatically detects the kernel version and the
compiler used for the kernel. Then it downloads the original kernel
sources, applies configurable patches and builds. And last but not
least it takes care to bring the module into the initramfs.

The alx-wol can be seen as one example for that mechanism. There are
two more examples which can be found in 'other_examples'.

## Compatibility

alx-wol 3.0 has been tested on Debian 12 (Bookworm), Ubuntu 24.4 (Noble Numbat),
Proxmox VE 8.3-1, Fedora 41-1.4, Arch 2025-02-01 and Suse Leap 15.6.

## How to use it

- take care to fulfill the distribution related requirements (see below)
- clone the git repository
- cd into alx-wol
- execute *as root* **./install.sh**  
  you may use **sudo** for the execution

## Distribution dependent requirements

### Debian

Before doing the installation on a Debian system please install dkms and wget.

`sudo apt install dkms wget`

### Ubuntu

The installation requires dkms to be installed.

`sudo apt install dkms`

If you want to install a kernel from the
[Ubuntu Mainline Kernel PPA](https://kernel.ubuntu.com/mainline/)
you need to know that Ubuntu may use different compilers for those kernel.
Either check in advance if the compilers you have installed are able to
compile the module or - in the case compilation crashes - check the log which
is mentioned by the installation process for the missing compiler.

As example I can tell the Ubuntu 24.04.5 standard kernel is compiled with gcc-13
while the mainline kernel 6.12 is compiled with gcc-14. New compiler parameter
are used, therefore the compilation fails. Checking the log file points to
different compiler used.

After this finding you can install the required compiler
(in that case `sudo apt install gcc-14) and the module will be compiled
and installed.

### Proxmox

To be able to install alx-wol on a Proxmos system dkms and the matching linux
headers have to be installed.

`sudo apt install dkms proxmox-headers-$(uname -r)`

I didn't check the Proxmox update mechanisms. Because of this a kernel update
should be carefully checked as I don't know if the headers are updated together
with the kernel. For me it is a bit strange that the installation of dkms
doesn't lead to the linux headers matching to the current kernel.

### Arch linux

There are multiple possibilities to install an Arch linux system. Any of these
requires dkms, wget, which and linux-headers to be installed.

`pacman -S dkms wget which linux-headers`

I didn't check the regular Arch update mechanism. Please check the logs when
Arch does a kernel update.

### Fedora

On Fedora systems dkms has to be installed before alx-wol installation.

I faced some issues when doing the installation while the system didn't finish
the update process. Therefor please FIRST do an upgrade, then execute a reboot
and after that install dkms and do the alx-wol installation.

`sudo yum upgrade`  
`sudo reboot` (or execute a manual reboot)  
`sudo yum install dkms`

I didn't check the regular Fedora update mechanism. Please check the logs when
Fedora does a kernel update.

### Suse

The default Suse installation doesn't contain patch, so additionally to dkms
patch has to be installed, too.

On Suse, comparable to Fedora, I faced issues when doing the installation
without a complete update in advance.

`sudo zypper update`  
`sudo reboot` (or execute a manual reboot)  
`sudo zypper install dkms path`

I didn't check the regular Suse update mechanism. Please check the logs when
Suse does a kernel update.

## Ho to remove it

Calling the script `remove.sh` will remove all installed versions of
this package from dkms. Only the installed data will be removed, the
sources are not removed with the script.

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

# Documentation for the generic dkms mechanism

The new generic kernel module patch mechanism is explained
[here](kernelpatching.md)

# Known issues

There is an issue when setting the Wake-on feature to `d`. If this is done
the ethernet interface doesn't come up after system wakes up after a suspend.

To recover from this there are two possibilities:

- execute a reboot
- execute the following sequence:  
  `sudo rmmod alx`  
  `sudo insmod $(find /lib/modules/$(uname -r)/ -name 'alx.*' | grep -v /kernel/)`


# History

**Version 3.0**

Change kernel version and compiler used detection.
With this the mechanism should work on nearly any distribution.

**Version 2.1.2**

First try to add Arch Linux support

**Version 2.1.1**

First try to add Proxmox support

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
