NONSNAP_GRUB_MODULES = \
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
	regexp \
	search \
	search_fs_uuid \
	search_fs_file \
	search_label \
	sleep \
	squash4 \
	test \
	true \
	video

all:
	dd if=$(SNAPCRAFT_STAGE)/usr/lib/grub/i386-pc/boot.img of=pc-boot.img bs=440 count=1
	/bin/echo -n -e '\x90\x90' | dd of=pc-boot.img seek=102 bs=1 conv=notrunc
	grub-mkimage -d $(SNAPCRAFT_STAGE)/usr/lib/grub/i386-pc/ -O i386-pc -o pc-core.img -p '(,gpt2)/EFI/ubuntu' $(GRUB_MODULES)
	# The first sector of the core image requires an absolute pointer to the
	# second sector of the image.  Since this is always hard-coded, it means our
	# BIOS boot partition must be defined with an absolute offset.  The
	# particular value here is 2049, or 0x01 0x08 0x00 0x00 in little-endian.
	/bin/echo -n -e '\x01\x08\x00\x00' | dd of=pc-core.img seek=500 bs=1 conv=notrunc
	# We must pull in dualsigned shim & grub with UC20 signature
	# Do it by hand, as snapcraft doesn't have support for PPA archives yet
	# And yet people try to rebuild this gadget snap
	pull-lp-debs -a amd64 -D ppa --ppa ppa:canonical-foundations/uc20-staging-ppa shim-signed focal
	dpkg-deb -x shim-signed_*.deb shim/
	pull-lp-debs -a amd64 -D ppa --ppa ppa:canonical-foundations/uc20-staging-ppa shim focal
	dpkg-deb -x shim_*.deb shim/
	pull-lp-debs -a amd64 -D ppa --ppa ppa:canonical-foundations/uc20-staging-ppa grub-efi-amd64-signed focal || wget https://launchpad.net/~canonical-signing/+archive/ubuntu/uc20/+build/19903679/+files/grub-efi-amd64-signed_1.142.5+uc20.1+2.04-1ubuntu26.3_amd64.deb
	dpkg-deb -x grub-efi-amd64-signed_*.deb grub/
	cp shim/usr/lib/shim/shimx64.efi.dualsigned shim.efi.signed
	cp shim/usr/lib/shim/fbx64.efi .
	cp shim/usr/lib/shim/mmx64.efi .
	cp shim/usr/lib/shim/BOOTX64.CSV .
	cp grub/usr/lib/grub/x86_64-efi-signed/grubx64.efi.signed grubx64.efi

install:
	install -m 644 pc-boot.img pc-core.img shim.efi.signed grubx64.efi $(DESTDIR)/
	install -m 644 fbx64.efi mmx64.efi BOOTX64.CSV $(DESTDIR)/
	install -m 644 grub.conf $(DESTDIR)/
