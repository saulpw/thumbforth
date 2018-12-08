MEMORY
{
    flash (rx) : ORIGIN = 0x00000000, LENGTH = 256K
    ram (rwx)  : ORIGIN = 0x20000000, LENGTH =  64K
}

SECTIONS
{
   .text : { *(.text*) } > flash
   .data : { *(.data*) } > ram
}
