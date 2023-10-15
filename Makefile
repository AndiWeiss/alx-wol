ifneq "$(filter 5.1%,$(kernelver))" ""
obj-m += alx_5.19/
alx-wol-version_found = true
endif

ifneq "$(filter 6.0.%,$(kernelver))" ""
obj-m += alx_6.0/
alx-wol-version_found = true
endif

ifneq "$(filter 6.1.%,$(kernelver))" ""
obj-m += alx_6.1/
alx-wol-version_found = true
endif

ifneq "$(filter 6.2.%,$(kernelver))" ""
obj-m += alx_6.2/
alx-wol-version_found = true
endif

ifneq "$(filter 6.3.%,$(kernelver))" ""
obj-m += alx_6.3/
alx-wol-version_found = true
endif

ifneq "$(filter 6.4.%,$(kernelver))" ""
obj-m += alx_6.4/
alx-wol-version_found = true
endif

ifneq "$(filter 6.5.%,$(kernelver))" ""
obj-m += alx_6.5/
alx-wol-version_found = true
endif

ifeq "$(alx-wol-version_found)" ""
$(error kernel version $(kernelver) not supported by this alx-wol version)
endif
