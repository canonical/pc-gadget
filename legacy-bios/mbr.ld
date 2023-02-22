OUTPUT_FORMAT("binary");
ENTRY(start);
SECTIONS
{
    . = 0x7c00;
    .text : AT(0x7c00) {
        *(.text);
    }
    .data : {
        *(.data);
    }
    /DISCARD/ : {
        *(*);
    }
}
