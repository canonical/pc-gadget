all: mbr.img

legacy-bios/mbr.o: legacy-bios/mbr.s
	gcc -Wall -O0 -c -m16 $< -o $@

legacy-bios/mbr.bin: legacy-bios/mbr.o legacy-bios/mbr.ld
	ld -melf_i386 -T legacy-bios/mbr.ld legacy-bios/mbr.o -o $@

mbr.img: legacy-bios/mbr.bin
	dd if=legacy-bios/mbr.bin of=mbr.img bs=440 count=1

install:
	install -m 644 mbr.img $(DESTDIR)/

.PHONY: install all
