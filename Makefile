# this gadget can be built in two ways, either through snapcraft (and then a prebuilt gadget
# is passed to ubuntu-image), or through make ARCH=a SERIES=s by livecd-rootfs or ubuntu-image

ifdef SNAPCRAFT_STAGE
STAGEDIR ?= "$(SNAPCRAFT_STAGE)"
else
STAGEDIR ?= "$(CURDIR)/stage"
endif

# ARCH should be set by livecd-rootfs or ubuntu-image, or through
# SNAPCRAFT_TARGET_ARCH by snapcraft; output a warning if unset (e.g. local build)
ifdef SNAPCRAFT_TARGET_ARCH
ARCH := $(SNAPCRAFT_TARGET_ARCH)
endif
ifndef ARCH
ARCH := $(shell dpkg --print-architecture)
$(warning Setting ARCH to $(ARCH) for local build)
endif

# SERIES should be set by livecd-rootfs or snapcraft should setup a clean environment; output a
# warning if unset (e.g. local build)
ifndef SERIES
SERIES := $(shell . /etc/os-release && echo $$UBUNTU_CODENAME)
# no target series env var in snapcraft
ifndef SNAPCRAFT_STAGE
$(warning Setting SERIES to $(SERIES) for local build)
endif
endif


DESTDIR ?= "$(CURDIR)/install"
SHIM_SIGNED := $(STAGEDIR)/usr/lib/shim/shimx64.efi.signed
SHIM_LATEST := $(SHIM_SIGNED).latest

# filtered list of modules included in the signed EFI grub image, excluding
# ones that we don't think are useful in snappy.
GRUB_MODULES = \
	all_video \
	biosdisk \
	boot \
	cat \
	chain \
	configfile \
	echo \
	ext2 \
	fat \
	font \
	gettext \
	gfxmenu \
	gfxterm \
	gfxterm_background \
	gzio \
	halt \
	jpeg \
	keystatus \
	loadenv \
	loopback \
	linux \
	memdisk \
	minicmd \
	normal \
	part_gpt \
	png \
	reboot \
	search \
	search_fs_uuid \
	search_fs_file \
	search_label \
	sleep \
	squash4 \
	test \
	true \
	btrfs \
	hfsplus \
	iso9660 \
	part_apple \
	part_msdos \
	password_pbkdf2 \
	zfs \
	zfscrypt \
	zfsinfo \
	lvm \
	mdraid09 \
	mdraid1x \
	raid5rec \
	raid6rec \
	video

# Download the latest version of package $1 for architecture $(ARCH), unpacking
# it into $(STAGEDIR). For example, the following invocation will download the
# latest version of u-boot-rpi for armhf, and unpack it under STAGEDIR:
#
#  $(call stage_package,u-boot-rpi)
#
define stage_package
	mkdir -p $(STAGEDIR)/tmp
	# setup chdist APT environment for SERIES-ARCH and run apt update
	if [ ! -d  $(STAGEDIR)/tmp/chdist ]; then \
	    chdist -d $(STAGEDIR)/tmp/chdist -a $(ARCH) create $(SERIES)-$(ARCH); \
	    echo "deb http://archive.ubuntu.com/ubuntu/ $(SERIES) main" >$(STAGEDIR)/tmp/chdist/$(SERIES)-$(ARCH)/etc/apt/sources.list; \
	    echo "deb http://archive.ubuntu.com/ubuntu/ $(SERIES)-updates main" >>$(STAGEDIR)/tmp/chdist/$(SERIES)-$(ARCH)/etc/apt/sources.list; \
	    if [ -n "$$PROPOSED" ]; then \
	        echo "deb http://archive.ubuntu.com/ubuntu/ $(SERIES)-proposed main" >>$(STAGEDIR)/tmp/chdist/$(SERIES)-$(ARCH)/etc/apt/sources.list; \
	    fi; \
	    chdist -d $(STAGEDIR)/tmp/chdist -a $(ARCH) apt $(SERIES)-$(ARCH) update; \
	fi
	# download and unpack package
	cd $(STAGEDIR)/tmp && \
	    chdist -d $(STAGEDIR)/tmp/chdist -a $(ARCH) apt $(SERIES)-$(ARCH) download $(1)
	dpkg-deb --extract $(STAGEDIR)/tmp/$(1)_*.deb $(STAGEDIR)
endef

all: boot install

boot:
	# Check if we're running under snapcraft. If not, we need to 'stage'
	# some packages by ourselves.
ifndef SNAPCRAFT_PROJECT_NAME
	$(call stage_package,grub-pc-bin)
	$(call stage_package,grub-efi-amd64-signed)
	$(call stage_package,shim-signed)
endif
	dd if=$(STAGEDIR)/usr/lib/grub/i386-pc/boot.img of=pc-boot.img bs=440 count=1
	/bin/echo -n -e '\x90\x90' | dd of=pc-boot.img seek=102 bs=1 conv=notrunc
	grub-mkimage -d $(STAGEDIR)/usr/lib/grub/i386-pc/ -O i386-pc -o pc-core.img -p '(,gpt2)/EFI/ubuntu' $(GRUB_MODULES)
	# The first sector of the core image requires an absolute pointer to the
	# second sector of the image.  Since this is always hard-coded, it means our
	# BIOS boot partition must be defined with an absolute offset.  The
	# particular value here is 2049, or 0x01 0x08 0x00 0x00 in little-endian.
	/bin/echo -n -e '\x01\x08\x00\x00' | dd of=pc-core.img seek=500 bs=1 conv=notrunc

	if [ -f "$(SHIM_LATEST)" ]; then \
		cp $(SHIM_LATEST) shim.efi.signed; \
	else \
		cp $(SHIM_SIGNED) shim.efi.signed; \
	fi
	cp $(STAGEDIR)/usr/lib/grub/x86_64-efi-signed/grubx64.efi.signed grubx64.efi

install:
	mkdir -p $(DESTDIR)
	install -m 644 pc-boot.img pc-core.img shim.efi.signed grubx64.efi $(DESTDIR)/
	install -m 644 grub.conf grub.cfg $(DESTDIR)/
	# For classic builds we also need to prime the gadget.yaml
	mkdir -p $(DESTDIR)/meta
	cp gadget.yaml $(DESTDIR)/meta/

# only used locally, not relevant for snapcraft, livecd-rootfs or ubuntu-image
clean:
	rm -rf $(STAGEDIR)
	rm -f pc-boot.img pc-core.img shim.efi.signed grubx64.efi
	rm -rf $(DESTDIR)

