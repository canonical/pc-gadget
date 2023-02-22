all: mbr.img
	# We must pull in dualsigned shim & grub with UC20 signature
	# Do it by hand, as snapcraft doesn't have support for PPA archives yet
	# And yet people try to rebuild this gadget snap
	pull-lp-debs -a amd64 -D ppa --ppa ppa:canonical-foundations/uc20-staging-ppa shim-signed jammy
	dpkg-deb -x shim-signed_*.deb shim/
	pull-lp-debs -a amd64 -D ppa --ppa ppa:canonical-foundations/uc20-staging-ppa grub2-signed jammy
	dpkg-deb -x grub-efi-amd64-signed_*.deb grub/
	cp shim/usr/lib/shim/shimx64.efi.dualsigned shim.efi.signed
	cp grub/usr/lib/grub/x86_64-efi-signed/grubx64.efi.signed grubx64.efi

legacy-bios/mbr.o: legacy-bios/mbr.s
	gcc -Wall -O0 -c -m16 $< -o $@

legacy-bios/mbr.bin: legacy-bios/mbr.o legacy-bios/mbr.ld
	ld -melf_i386 -T legacy-bios/mbr.ld legacy-bios/mbr.o -o $@

mbr.img: legacy-bios/mbr.bin
	dd if=legacy-bios/mbr.bin of=mbr.img bs=440 count=1

install:
	install -m 644 mbr.img shim.efi.signed grubx64.efi $(DESTDIR)/
	install -m 644 grub.conf $(DESTDIR)/
	install -d $(DESTDIR)/meta
	install -m 644 gadget.yaml $(DESTDIR)/meta/

.PHONY: install all
