MEMORY {
    /* 32KB RAM at address 0x00000000 */
    ram (rwx) : ORIGIN = 0x00000000, LENGTH = 0x00008000
}

SECTIONS {
    /* Place code first */
    .text : {
        /* Ensure start.o is placed at the very beginning (0x0) */
        *(.text.start)
        *(.text*)
    } > ram

    /* Read-only and read-write data */
    .data : {
        *(.data*)
        *(.rodata*)
    } > ram

    /* Uninitialized variables */
    .bss : {
        *(.bss*)
        *(COMMON)
    } > ram
}
