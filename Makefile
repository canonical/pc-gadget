all:
	# We must pull in dualsigned shim & grub with UC signature
	# Do it by hand, as snapcraft doesn't have support for PPA archives yet
	# And yet people try to rebuild this gadget snap
	# TODO not yet available for arm64
	pull-lp-debs -a arm64 -D ppa --ppa ppa:ucdev/uc-staging-ppa shim-signed jammy
	dpkg-deb -x shim-signed_*.deb shim/
	pull-lp-debs -a arm64 -D ppa --ppa ppa:ucdev/uc-staging-ppa grub2-signed jammy
	dpkg-deb -x grub-efi-arm64-signed_*.deb grub/
	cp shim/usr/lib/shim/shimaa64.efi.dualsigned shim.efi.signed
	cp grub/usr/lib/grub/arm64-efi-signed/grubaa64.efi.signed grubaa64.efi

install:
	install -m 644 shim.efi.signed grubaa64.efi $(DESTDIR)/
	install -m 644 grub.conf $(DESTDIR)/
	install -d $(DESTDIR)/meta
	install -m 644 gadget.yaml $(DESTDIR)/meta/
