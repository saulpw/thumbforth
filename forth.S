/*  Forth for LM3S6965 (ARM Cortext M4) */

@ register allocations
#define rWP r4   /* data pointer */
#define rTOS r5  /* top of stack */
#define rRP r6   /* return stack pointer */
#define rIP r7   /* forth next word pointer */
#define rSP sp   /* parameter stack pointer */

@ memory map
.equ SP0, 0x20000ffc
.equ RP0, 0x20001000

.equ UARTDR, 0x4000C000

.text
.align 4

@@@ exception/interrupt vector table in memory at 0x0
.4byte SP0        @ initial SP
.4byte _reset     @ reset PC
.4byte _exc2      @ nmi
.4byte _exc3      @ hard fault
.4byte _exc4      @ mm fault
.4byte _exc5      @ bus fault
.4byte _exc6      @ usage fault
@ ... other interrupts not handled ...

@@ exception handlers in ARM format
.arm
_exc2: b _exc2
_exc3: b _exc3
_exc4: b _exc4
_exc5: b _exc5
_exc6: b _exc6

@ rest of code in Thumb format
.thumb

forth_start:
.4byte INIT, HALT

@@ reset handler inits the Forth registers and kicks the whole thing off at INIT
.globl _reset
.thumb_func
_reset:
    ldr rRP, =RP0
    mov rTOS, #0
    ldr rIP, =forth_start
    b NEXT

NEXT:
    ldr r0, [rIP]    @ load next word pointer
    add rIP, #4

    add rWP, r0, #4  @ setup data pointer for code word

    ldr r0, [r0]     @ indirect threading
    bx r0            @ jump to code word

@@@ code word definitions (rWP will contain pointer to data immediately following code word pointer)
@@ each must be preceded by .thumb_func for their pointers to have bit 0 set for Thumb instruction set

.thumb_func
ENTER:
    str rIP, [rRP]
    add rRP, #4
    mov rIP, rWP
    b NEXT

@@@ manually defined composite forth words
@@ must *not* use .thumb_func, or their pointers will have bit 0 set

INIT:
.4byte ENTER
.4byte PROMPT, KEY, QDUP, BRANCHZ, -4, EMIT, BRANCH, -7, EXIT

PROMPT:
.4byte ENTER
.4byte DOLIT, 'O', EMIT, DOLIT, 'K', EMIT, DOLIT, 13, EMIT, EXIT

@ native words
@@ each must be preceded by its own thumb address (ready to be branched to)
@@ must *not* use .thumb_func themselves, or their pointers will have bit 0 set

.macro native NAME
\NAME: .4byte _\NAME
.thumb_func
_\NAME:
.endm

native EXIT
    sub rRP, #4
    ldr rIP, [rRP]
    b NEXT

native DOLIT
    push {rTOS}
    ldr rTOS, [rIP]
    add rIP, #4
    b NEXT

native DUP
    push {rTOS}
    b NEXT

native DROP
    pop {rTOS}
    b NEXT

native SWAP
    pop {r0}
    push {rTOS}
    mov rTOS, r0
    b NEXT

native EMIT
    ldr r0, =UARTDR
    str rTOS, [r0]
    pop {rTOS}
    b NEXT

native KEY
    push {rTOS}
    ldr r0, =UARTDR
    ldr rTOS, [r0]
    b NEXT

native QDUP
    cmp rTOS, #0
    beq NEXT
    push {rTOS}
    b NEXT

native BRANCH
    ldr r0, [rIP]
    add rIP, #4

    lsl r0, #2
    add rIP, r0
    b NEXT

native BRANCHZ
    ldr r0, [rIP]
    add rIP, #4

    cmp rTOS, #0
    bne .done

    lsl r0, #2
    add rIP, r0

.done:
    pop {rTOS}
    b NEXT

native HALT
_halt: b _halt
