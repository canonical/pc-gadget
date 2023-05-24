ifdef SNAPCRAFT_STAGE
STAGEDIR ?= "$(SNAPCRAFT_STAGE)"
else
STAGEDIR ?= "$(CURDIR)/stage"
endif
DESTDIR ?= "$(CURDIR)/install"
ARCH ?= $(shell dpkg --print-architecture)
SHIM_SIGNED := $(STAGEDIR)/usr/lib/shim/shimaa64.efi.signed
SHIM_LATEST := $(SHIM_SIGNED).latest

# Download the latest version of package $1 for architecture $(ARCH), unpacking
# it into $(STAGEDIR). For example, the following invocation will download the
# latest version of u-boot-rpi for armhf, and unpack it under STAGEDIR:
#
#  $(call stage_package,u-boot-rpi)
#
define stage_package
	mkdir -p $(STAGEDIR)/tmp
	( \
		cd $(STAGEDIR)/tmp && \
		apt-get download \
			-o APT::Architecture=$(ARCH) $$( \
				apt-cache \
					-o APT::Architecture=$(ARCH) \
					showpkg $(1) | \
					sed -n -e 's/^Package: *//p' | \
					sort -V | tail -1 \
			); \
	)
	dpkg-deb --extract $$(ls $(STAGEDIR)/tmp/$(1)*.deb | tail -1) $(STAGEDIR)
endef

all: boot install

boot:
	# Check if we're running under snapcraft. If not, we need to 'stage'
	# some packages by ourselves.
ifndef SNAPCRAFT_PROJECT_NAME
	$(call stage_package,grub-efi-arm64-bin)
	$(call stage_package,grub-efi-arm64-signed)
	$(call stage_package,shim-signed)
endif
	if [ -f "$(SHIM_LATEST)" ]; then \
		cp $(SHIM_LATEST) shim.efi.signed; \
	else \
		cp $(SHIM_SIGNED) shim.efi.signed; \
	fi
	cp $(STAGEDIR)/usr/lib/grub/arm64-efi-signed/grubaa64.efi.signed grubaa64.efi

install:
	mkdir -p $(DESTDIR)
	install -m 644 shim.efi.signed grubaa64.efi $(DESTDIR)/
	install -m 644 grub.conf grub.cfg $(DESTDIR)/
	# For classic builds we also need to prime the gadget.yaml
	mkdir -p $(DESTDIR)/meta
	cp gadget.yaml $(DESTDIR)/meta/
