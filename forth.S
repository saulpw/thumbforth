/*  Forth for LM3S6965 (ARM Cortext M4) */

@ register allocations
#define rWP r4   /* data pointer */
#define rTOS r5  /* top of stack */
#define rRP r6   /* return stack pointer */
#define rIP r7   /* forth next word pointer */
#define rSP sp   /* parameter stack pointer */
                 /* lr holds a pointer to NEXT */

@ memory map

.equ SP0, 0x20000ffc
.equ RP0, 0x20001000
.equ CPADDR, 0x20000100
.equ LASTADDR, 0x20000104
.equ PADADDR, 0x20000204

.text
.align 4

@@@ exception/interrupt vector table in memory at 0x0
.4byte SP0        @  0  initial SP
.4byte _reset     @  1  reset PC
.4byte _exc       @  2  nmi
.4byte _exc       @  3  hard fault
.4byte _exc       @  4  mm fault
.4byte _exc       @  5  bus fault
.4byte _exc       @  6  usage fault
.4byte 0          @  7  reserved
.4byte 0          @  8  reserved
.4byte 0          @  9  reserved
.4byte 0          @ 10  reserved
.4byte _exc       @ 11  SVCall
.4byte _exc       @ 12  reserved for debug
.4byte 0          @ 13  reserved
.4byte _exc       @ 14  PendSV
.4byte _exc       @ 15  Systick
.4byte _exc       @ 16  IRQ0
.4byte _exc       @ 17  IRQ1
.4byte _exc       @ 18  IRQ2

@ ... other interrupts not handled ...

.thumb            @ all code in Thumb format
.thumb_func
_exc: b _exc

forth_start:
.4byte INIT, HALT

.macro NEXT
    bx lr
.endm

@@ reset handler inits the Forth registers and kicks the whole thing off at INIT
.globl _reset
.thumb_func
_reset:
    ldr rRP, =RP0
    mov rTOS, #0
    ldr rIP, =forth_start

    ldr r0, =kernel
    ldr r1, =CPADDR
    str r0, [r1]

    ldr r0, =_NEXT
    mov lr, r0

@    ldr r0, ??
@    ldr r1, =LASTADDR
@    str r0, [r1]
    NEXT

.thumb_func
_NEXT:
    ldr rWP, [rIP]    @ load next word pointer
    add rIP, #4

    ldr r0, [rWP]     @ indirect threading
    bx r0             @ jump to code word

@@@ code word definitions (rWP will contain pointer to data immediately following code word pointer)
@@ each must be preceded by .thumb_func for their pointers to have bit 0 set for Thumb instruction set

.thumb_func
ENTER:
    str rIP, [rRP]
    add rRP, #4

    add rIP, rWP, #4  @ setup data pointer for code word
    NEXT

.thumb_func
DOCONST:
    push {rTOS}
    add rWP, #4
    ldr rTOS, [rWP]
    NEXT

.thumb_func
DOVAR:
    push {rTOS}
    add rTOS, rWP, #4
    NEXT

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
    NEXT

native DOLIT  @ ( -- v )
    push {rTOS}
    ldr rTOS, [rIP]
    add rIP, #4
    NEXT

native DUP  @ ( a -- a a )
    push {rTOS}
    NEXT

native DROP  @ ( a -- )
    pop {rTOS}
    NEXT

native SWAP  @ ( a b -- b a )
    pop {r0}
    push {rTOS}
    mov rTOS, r0
    NEXT

native STORE  @ ( val addr -- )
    mov r0, rTOS
    pop {r1}
    pop {rTOS}
    str r1, [r0]
    NEXT

native FETCH  @ ( addr -- val )
    ldr rTOS, [rTOS]
    NEXT

native CFETCH  @ ( addr -- b )
    ldrb rTOS, [rTOS]
    NEXT

native QDUP  @ ( 0|x -- 0 | x x )
    cmp rTOS, #0
    beq .QDUP.done
    push {rTOS}
.QDUP.done:
    NEXT

native BRANCH  @ ( -- )
    ldr r0, [rIP]
    add rIP, #4

    lsl r0, #2
    add rIP, r0
    NEXT

native BRANCHZ  @ ( bool -- )
    ldr r0, [rIP]
    add rIP, #4

    cmp rTOS, #0
    bne .BRANCHZ.done

    lsl r0, #2
    add rIP, r0

.BRANCHZ.done:
    pop {rTOS}
    NEXT

native HALT  @ ( -- )
_halt: b _halt

native PLUS  @ ( a b -- a+b )
    pop {r0}
    add rTOS, r0
    NEXT

native EXECUTE  @ ( ? xt -- ? )
    mov rWP, rTOS
    pop {rTOS}
    b ENTER

native CALLC1  @ ( a -- func[a] )
    mov r0, rTOS
    ldr r2, [rIP]
    add rIP, #4
    blx r2
    mov rTOS, r0
    NEXT

native CALLC2  @ ( a b -- func[a,b] )
    mov r0, rTOS
    pop {r1}
    ldr r2, [rIP]
    add rIP, #4
    blx r2
    mov rTOS, r0
    NEXT

@@@ manually defined composite forth words
@@ must *not* use .thumb_func, or their pointers will have bit 0 set

INIT: @ ( -- )
.4byte ENTER
.4byte PROMPT, KEY, EMIT, BRANCH, -4, EXIT

LAST: .4byte DOCONST, LASTADDR  @ pointer to Last entry in dict
CP: .4byte DOCONST, CPADDR      @ Char Pointer
PAD: .4byte DOCONST, PADADDR    @ scratch pad

INTERPRET:  @  0 WORD FIND IF EXECUTE ELSE >NUMBER THEN ;
.4byte ENTER
.4byte DOLIT, 0, WORD, FIND, BRANCHZ, +3
.4byte EXECUTE, BRANCH, +1, TONUM, EXIT

PROMPT: @ ( -- )
.4byte ENTER
.4byte DOLIT, _prompt, TYPE, EXIT

_prompt: .asciz "READY> "

UARTDR: .4byte DOCONST, 0x4000C000  @ Data Register
UARTSR: .4byte DOCONST, 0x4000C004  @ Status Register
UARTFR: .4byte DOCONST, 0x4000C008  @ Flag Register
UARTIM: .4byte DOCONST, 0x4000C038  @ Interrupt Mask

KEY: @ ( -- k ) BEGIN UARTDR @ ?DUP UNTIL ;
.4byte ENTER
.4byte UARTDR, FETCH, QDUP, BRANCHZ, -5, EXIT

EMIT: @ ( c -- ) UARTDR ! ;
.4byte ENTER
.4byte UARTDR, STORE, EXIT

TYPE:  @ ( str -- ) BEGIN DUP C@ ?DUP NOT IF EXIT THEN EMIT 1 + AGAIN ;
.4byte ENTER
.4byte DUP, CFETCH, QDUP, BRANCHZ, +6, EMIT, DOLIT, 1, PLUS, BRANCH, -11, EXIT

DOT:  @ ( n -- ) [CHAR] 0 + EMIT ;
.4byte ENTER
.4byte DOLIT, '0', PLUS, EMIT, EXIT

WORD: @ ( delim -- tokptr )
.4byte ENTER
.4byte DROP  @ ignore delim for now
.4byte CP, FETCH, PAD, CALLC2, parse_token
.4byte CP, FETCH, PLUS, CP, STORE, PAD, EXIT

FIND: @ ( tok -- xt 1 | tok 0 )
.4byte ENTER
.4byte DUP, LAST, FETCH, CALLC2, find_entry  @ ( tok 0|ent )
.4byte DUP, BRANCHZ, +4, SWAP, DROP, DOLIT, 1, EXIT

TONUM: @ ( str -- n )
.4byte ENTER
.4byte CALLC1, atoi, EXIT

@@@ initial source input

kernel:
    .asciz "42 23 + ."
