ifneq "$(filter 5.1%,$(kernelver))" ""
obj-m += alx_5.19/
endif

ifneq "$(filter 6.0.%,$(kernelver))" ""
obj-m += alx_6.0/
endif

ifneq "$(filter 6.1.%,$(kernelver))" ""
obj-m += alx_6.1/
endif

ifneq "$(filter 6.2.%,$(kernelver))" ""
obj-m += alx_6.2/
endif

ifneq "$(filter 6.3.%,$(kernelver))" ""
obj-m += alx_6.3/
endif
