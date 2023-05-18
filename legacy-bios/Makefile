all: mbr.img

mbr.o: mbr.s
	gcc -Wall -O0 -c -m16 $< -o $@

mbr.bin: mbr.o mbr.ld
	ld -melf_i386 -T mbr.ld mbr.o -o $@

mbr.img: mbr.bin
	dd if=mbr.bin of=mbr.img bs=440 count=1

install:
	install -m 644 mbr.img $(DESTDIR)/

.PHONY: install all
