# alx-wol - atheros alx driver wol patch dkms

When using the Atheros alx driver on Ubuntu 20.04 the Wake On Lan
feature is functional as long as a kernel 5.14 is used.  
When switching to kernel 5.15 or newer the wol functionality is not
available anymore. Also using a newer Ubuntu version don't contain a
functional WOL with that ethernet interface.

This package adds the support for wol again as dkms package.

## * news *

**Version 3.3 supports CachyOS** Please keep in mind: this system supports no 
kernel release candidates.

**Version 3.2 contians the possibility to fetch the kernel sources out of a 
local git repository.** The patches have been checked up to kernel version 7.2.

**Version 3.1 contains new patches. With these the issue with Wake feature
configured to `d` is fixed since kernel version 6.5.**

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

Now I released version 3.2 of alx-wol.

And to be honest: this is much more than alx driver with wake on lan.
This version is a framework for creating kernel modules based on original
kernel sources. It automatically detects the kernel version and the
compiler used for building the kernel. Then it fetches the original kernel
sources, applies configurable patches and builds. And last but not
least it takes care to bring the module into the initramfs.

The alx-wol can be seen as one example for that mechanism. There are
two more examples which can be found in 'other_examples'.

## Compatibility

alx-wol 3.3 has been tested on Debian 13 (Trixie), Ubuntu 26.4 (Resolute 
Raccoon), Proxmox VE 9.2, Fedora 44, Arch (unknown version, 08-26), openSuse 
Tumbleweed (20260830) and CachyOs (unknown version, installation medium 
20260809).

The alx patches are full functional from kernel version 5.15 up to 7.3.

## How to use it

- take care to fulfill the distribution related requirements (see below)
- clone the git repository
- cd into alx-wol
- execute *as root* **./install.sh**  
  you may use **sudo** for the execution  
  *CAUTION!* in case of suse you have to use  
  `sudo bash install.sh`  
  *Caution!' in case of CachyOS you need to have a local linux kernel git 
  repository
- If you want to use a local kernel git repo as source:  
  add the parameter `local-linux-repo=<path_to_repo>`  
  If there is no local repo the install script will ask if it shall be cloned

## Distribution dependent requirements

### all distributions

If a local git repo shall be used don't forget to install git.

### Debian

Before doing the installation on a Debian system please install dkms and wget.

`sudo apt install dkms wget linux-headers-amd64`

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

To be able to install the headers you either have to have a valid subscription 
or you have to chose the `no-subscription`

`sudo apt install dkms pve-headers`

### Arch linux

There are multiple possibilities to install an Arch linux system. Any of these
require dkms, wget, which and linux-headers to be installed.

`pacman -S dkms wget which linux-headers`

### Fedora

On Fedora systems dkms has to be installed before alx-wol installation.

I faced some issues when doing the installation while the system didn't finish
the update process. Therefor please FIRST do an upgrade, then execute a reboot
and after that install dkms and do the alx-wol installation.

`sudo yum upgrade`  
`sudo reboot` (or execute a manual reboot)  
`sudo yum install dkms`

### CachyOs

In case of CachyOs I struggled hard with CachyOs behavior during `pacman -Syu` 
run. In a very early stage of the update CachyOS seems to cut all ethernet 
connections. With this the mechanism as it was used up to now - using `wget` to 
fetch the kernel sources for sure doesn't work.

Additionally I run into an issue with git.kernel.org. Because of heavy misuse 
kernel.org decided to limit the access on the files via regular https access. 
With this and my multiple tests of the mechanism I run again and again in 
`error 404 - file not found` during wget.

The access on the complete repo via git is not limited.

This was the point where I decided to add a feature to have a local git repo 
of the linux kernel and keep that updated. After I introduced that into version 
3.2 I started CachyOs analysis again.

Ethernet is shut down realy early during update. Therefore I introduce a new 
systemd service which keeps track of the linux git repository. As the complete 
service is defined by me I added it to the installation process.

So just use

`sudo ./install.sh local-linux-repo=<path_to_linux_repo>`

and the install script will ask you for the installation of the service.

The service is executed on each system start. It checks if the last repo 
fetch is more than one day ago. If yes it executes a `git fetch` on it. With 
this the update process will always find a fresh kernel repo containing all 
new version tags.

### Suse

The default Suse installation doesn't contain patch, so additionally to dkms
patch has to be installed, too.

The installation script can't be called by `sudo ./install.sh ...`  
Instead a bash has to be started with sudo to execute the install script:  
`sudo bash ./install.sh`

On Suse, comparable to Fedora, I faced issues when doing the installation
without a complete update in advance.

`sudo zypper update`  
`sudo reboot` (or execute a manual reboot)  
`sudo zypper install dkms patch`

Suse uses `dkms` different compared to any other distribution I've seen up to 
now. They don't use the kernel update hooks, instead they created a systemd 
target which executes a `dkms autoinstall` during the next startup.

Is I have to modify the original suse mechanisms I dind't bring the changes 
into the installation process. Instead the process checks if the expectations 
are fulfiled and stops if they aren't with a detailed information.

If you think that the suse system hasn't been modifed since I introduced the 
mechanism you can just compy two files and you're done. But I *strongly* 
recommend to check if the files still contain what I explain. In the case that 
Suse modifies those files and you replace them by my (now old, not matching) 
files you may break your system.

If you want to copy:

```
sudo cp tools/suse/dkms.service /usr/lib/systemd/system/dkms.service
sudo cp tools/suse/dkms_wrapper.sh /usr/sbin
sudo systemctl daemon-reload
sudo systemctl enable dkms.service
```

No the explanation what Suse does with dkms:

Suses `dkms.service` is started as a single shot rather early in the startup - 
long before ethernet is up and usable. To get the compilation work we depend on 
functional internet access. Therefore the systemd file has to be modifed.

The file `/usr/lib/systemd/system/dkms.service` contains the definition of the 
service. You can either modify the file as explained below or simply copy it 
from `tools/suse` directory. The command for copy is  
`sudo cp tools/suse/dkms.service /usr/lib/systemd/system/dkms.service`

There is a line  
`Before=network-pre.target graphical.target`  
This has to be modified to  
`After=network-online.target`

But that's not enough - it seems that at least the name service is still 
not available after this target. Therefore we also have to modify what gets 
called.

The line  
`ExecStart=/usr/sbin/dkms autoinstall --verbose --kernelver %v`  
is responsible to call dkms.

This start has to be slowed down until the name resoltion is functional. To do 
so I introduce the shell script `dkms_wrapper.sh` located in the `tools/suse` 
directory. Copy this file (you need root right for that) to `/usr/sbin`. The 
command to do so is  
`sudo cp tools/suse/dkms_wrapper.sh /usr/sbin`

After that change the line `ExecStart=/usr/sbin/dkms ...` to 
`ExecStart=/usr/sbin/dkms_wrapper.sh ...`. The script executes a loop to get 
the name resolution of `git.kernel.org` for max 10 times. As soon as that 
worked it calls `dkms` with all of the parameters.

To be sure that the system starts up even if the network stays down add the 
line  
`TimeoutSec=300`  
behind the `ExecStart` line.

This is still not enough for suse linux.

Calling the installation script `install.sh` (and also - if you want to remove 
alx-wol again - `remove.sh`) has to be done by starting it in a new shell. So 
instead of calling `sudo ./install.sh` one has to call `sudo bash ./install.sh`.

And in case of using a local git repo containing the linux sources this repo 
has to be owned by root. So you have to  
`sudo chown -R root:root <path_to_linux_repo>`  
before installation of alx-wol.

Last step is to reload the systemd configuration:

```
sudo systemctl daemon-reload
sudo systemctl enable dkms.service
```

Now - during the first startup after a kernel update - dkms will compile the 
alx-wol module. As this happens after the network came up I can't tell how 
a server may react. The network will stop working during installation of the 
compiled module and start working again when the new module is installed.

## How to remove it

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


**Caution!** Neither on CachyOs nor on Suse the additional modifications of 
the system are removed. You have to remove them by hand if you want to get rid 
of them.

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

Only kernel before 6.5:  
There is an issue when setting the Wake-on feature to `d`. If this is done
the ethernet interface doesn't come up after system wakes up after a suspend.

To recover from this there are two possibilities:

- execute a reboot
- execute the following sequence:  
  `sudo rmmod alx`  
  `sudo insmod $(find /lib/modules/$(uname -r)/ -name 'alx.*' | grep -v /kernel/)`

# History

**Version 3.3**

Added support for CachyOs (need a local kernel git repo for that)

**Version 3.2**

Possibility to use a local git repo instead of fetching with `wget`  
Patches checked up to kernel version 7.2.2

**Version 3.1**

New patches. These patches fix the 'Wake on lan disabled' issue since kernel 6.5

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
