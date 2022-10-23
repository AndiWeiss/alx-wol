# alx-wol - atheros alx driver wol patch dkms

When using the Atheros alx driver on Ubuntu 20.04 the Wake On Lan feature is functional as long as a kernel 5.14 is used.  
When switching to kernel 5.15 the wol functionality is not available anymore.

This package adds the support for wol again as dkms package.

## Where does it come from

This dkms bases on the currently most actual kernel sources, the v6.0.3.  
These alx sources are fetched during installation.  
I did a comparison beginning with kernel v5.15.50 until v6.0.3 and found only minor differences in the alx driver. That's the reason why I decided to use the v6.0.3 sources for all kernel versions.

The file **patches/0000-alx-wol-v6.0.3.patch** is used to add the wol functionality again.

## How to use it

- clone the git repository
- cd into alx-wol
- execute *as root* **./install_alx-wol.sh**  
  you may use **sudo** for the execution

The script will check if there's already an old version of this dkms.  
If yes this will be deinstalled.

After that the new version is installed.  
To do so the alx sources are fetched from kernel.org,  
then the dkms mechanism is called to install the package.

As last action the script removes the active alx module and installs the new one in the running system.

### Disclaimer

This package is provides AS IS.  
**Use it on your own risk.**  
The author doesn't take any responsibility for any kind of malfunction or data loss on your system.