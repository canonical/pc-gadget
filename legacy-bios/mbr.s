        .code16
        .section .text
        .globl start

start:
        jmp $0, $.entry
.entry:
        cli
        xorw %ax, %ax
        movw %ax, %ss
        movw %ax, %ds
        movw $0x7c00, %sp
        sti
        cld
        movw $.message, %si
.print:
        lodsb
        cmp $0, %al
        je .done
        push %si
        movb $0xe, %ah
        movw $0x0007, %bx
        int $0x10
        pop %si
        jmp .print
.done:
        cli
        hlt

        .section .data
.message:
	.string	"Please boot in EFI mode.\r\n\0"
