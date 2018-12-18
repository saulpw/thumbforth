/*  Forth for LM3S6965 (ARM Cortext M4) */

@ register allocations
#define rWP r4   /* data pointer */
#define rTOS r5  /* top of stack */
#define rRP r6   /* return stack pointer */
#define rIP r7   /* forth next word pointer */
#define rSP sp   /* parameter stack pointer */
                 /* lr holds a pointer to NEXT */

@ memory map

.set k_SP0, 0x20000ff8     @ Bottom parameter stack pointer (grows down)
.set k_RP0, 0x20001000     @ Bottom return stack pointer (grows up)
.set LASTWORD, 0x0         @ LAST maintained by macros
.set CPADDR, 0x20000100    @ Initial input
.set LASTADDR, 0x20000104  @ Initial LAST word
.set PADADDR, 0x20000204   @ allocated PAD area

.text
.align 4

@@@ exception/interrupt vector table in memory at 0x0
.4byte k_SP0      @  0  initial SP
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
    bl forth_init

    ldr rRP, =k_RP0
    mov rTOS, #0
    ldr rIP, =forth_start

    ldr r0, =_NEXT
    mov lr, r0        @ bx lr == b _NEXT

    NEXT

.pool  @ for constants in _reset

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
    add rRP, #4
    str rIP, [rRP]     @ RPUSH return IP

    add rIP, rWP, #4   @ PFA for ENTER is list of execution token (xt)
    NEXT

.thumb_func
DODOES:
    add rRP, #4
    str rIP, [rRP]     @ RPUSH return IP

    push {rTOS}
    add r0, rWP, #4    @ pointer to address of high-level code
    add rTOS, r0, #4   @ pointer to parameter field

    ldr rIP, [r0]      @ start interpreting DODOES thread

    NEXT

DOCONST: .4byte FETCH, EXIT

.macro defconst NAME, VALUE
dict \NAME
\NAME: .4byte DODOES, DOCONST, \VALUE
.endm

@ native words
@@ each must be preceded by its own thumb address (ready to be branched to)
@@ must *not* use .thumb_func themselves (because it is not callable code)

.macro dict NAME, FNAME
.section .rodata
name_\NAME:
    .asciz "\FNAME"

.section .text
dict_\NAME:
    .4byte LASTWORD
    .4byte name_\NAME

.set LASTWORD, dict_\NAME
.endm

.macro native NAME, FNAME
dict \NAME, \FNAME

\NAME:  @ execution token (xt)
    .4byte asm_\NAME

.thumb_func
asm_\NAME:
.endm

@ colon defs are the list of words to execute, finishing with EXIT
.macro colon NAME, FNAME
dict \NAME, \FNAME
\NAME:
.4byte ENTER
.endm

native EXIT, "EXIT"
    ldr rIP, [rRP]
    sub rRP, #4
    NEXT

native DOLIT, "DOLIT"  @ ( -- v )
    push {rTOS}
    ldr rTOS, [rIP]
    add rIP, #4
    NEXT

native DUP, "DUP"  @ ( a -- a a )
    push {rTOS}
    NEXT

native DROP, "DROP"  @ ( a -- )
    pop {rTOS}
    NEXT

native SWAP, "SWAP"  @ ( a b -- b a )
    pop {r0}
    push {rTOS}
    mov rTOS, r0
    NEXT

native OVER, "OVER"  @ ( a b -- a b a )
    push {rTOS}
    ldr rTOS, [rSP, #4]
    NEXT

native ROT, "ROT"  @ ( a b c -- b c a )
    pop {r1}
    pop {r0}
    push {r1}
    push {rTOS}
    mov rTOS, r0
    NEXT

native SPFETCH, "SP@"  @ ( -- psp )
    push {rTOS}
    add rTOS, rSP, #4  @ SP before SP was pushed
    NEXT

native RPFETCH, "RP@"  @ ( -- rsp )
    push {rTOS}
    mov rTOS, rRP
    NEXT

native R_TO, "R>"  @ (R: x -- ) ( -- x )
    push {rTOS}
    ldr rTOS, [rRP]     @ RPOP
    sub rRP, #4
    NEXT

native RDROP, "R>DROP"  @ (R: x -- )
    sub rRP, #4
    NEXT

native TO_R, ">R"  @ ( x -- ) (R: -- x )
    add rRP, #4
    str rTOS, [rRP]     @ RPUSH x
    pop {rTOS}
    NEXT

native EQUAL, "\x3D"  @ ( a b -- fl )
    pop {r0}
    mov r1, rTOS
    mov rTOS, #1  @ nonzero=equal
    cmp r0, r1
    beq EQUAL.done
    mov rTOS, #0  @ zero=not equal
EQUAL.done:
    NEXT

native STORE, "!"  @ ( val addr -- )
    mov r0, rTOS
    pop {r1}
    pop {rTOS}
    str r1, [r0]
    NEXT

native FETCH, "@"  @ ( addr -- val )
    ldr rTOS, [rTOS]
    NEXT

native CFETCH, "C@"  @ ( addr -- b )
    ldrb rTOS, [rTOS]
    NEXT

native QDUP, "?DUP"  @ ( 0|x -- 0 | x x )
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

native BRANCHNZ, "BRANCHNZ"  @ ( bool -- )
    ldr r0, [rIP]
    add rIP, #4

    cmp rTOS, #0
    beq .BRANCHNZ.done

    lsl r0, #2
    add rIP, r0

.BRANCHNZ.done:
    pop {rTOS}
    NEXT

native HALT, "HALT"  @ ( -- )
_halt: b _halt

native PLUS, "+"  @ ( a b -- a+b )
    pop {r0}
    add rTOS, r0
    NEXT

native NOT, "NOT"   @ ( a -- ~a )
    mov r0, rTOS
    mov rTOS, #0
    cmp r0, #0
    bne NOT.done
    sub rTOS, #1
NOT.done:
    NEXT

native EXECUTE, "EXECUTE"  @ ( ? xt -- ? )
    mov rWP, rTOS
    pop {rTOS}
    b ENTER

native CALLC1, "CALLC1"  @ ( a -- func[a] )
    mov r0, rTOS
    ldr r2, [rIP]
    add rIP, #4

    blx r2
    mov rTOS, r0

    ldr r0, =_NEXT       @ re-setup NEXT
    mov lr, r0
    NEXT

native CALLC2, "CALLC2"  @ ( a b -- func[a,b] )
    mov r0, rTOS
    pop {r1}
    ldr r3, [rIP]
    add rIP, #4

    blx r3
    mov rTOS, r0

    ldr r0, =_NEXT       @ re-setup NEXT
    mov lr, r0
    NEXT

native CALLC3, "CALLC3"  @ ( a b c -- func[a,b,c] )
    mov r0, rTOS
    pop {r1}
    pop {r2}
    ldr r3, [rIP]
    add rIP, #4

    blx r3
    mov rTOS, r0

    ldr r0, =_NEXT       @ re-setup NEXT
    mov lr, r0
    NEXT

@@@ manually defined composite forth words
@@ must *not* use .thumb_func, or their pointers will have bit 0 set

colon INIT, "INIT" @ ( -- )
.4byte TEST, WORDS, PROMPT, KEY, EMIT, BRANCH, -4, EXIT

defconst SP0, k_SP0-8    @ first element of parameter stack
defconst RP0, k_RP0+4    @ bottom of return stack
defconst CP, CPADDR      @ Char Pointer
defconst PAD, PADADDR    @ scratch pad
defconst LAST, LASTADDR  @ pointer to last entry in pre-assembled dict

colon INTERPRET, "INTERPRET"  @  0 WORD FIND IF EXECUTE ELSE >NUMBER THEN ;
.4byte DOLIT, 0, WORD, FIND, BRANCHZ, +3
.4byte EXECUTE, BRANCH, +1, TONUM, EXIT

colon PROMPT, PROMPT @ ( -- )
.4byte DOLIT, _prompt, TYPE, EXIT

_prompt:
.byte 13, 10
.asciz "READY> "

defconst UARTDR, 0x4000C000  @ Data Register
defconst UARTSR, 0x4000C004  @ Status Register
defconst UARTFR, 0x4000C008  @ Flag Register
defconst UARTIM, 0x4000C038  @ Interrupt Mask

colon KEY, "KEY" @ ( -- k ) BEGIN UARTDR @ ?DUP UNTIL ;
.4byte UARTDR, FETCH, QDUP, BRANCHZ, -5, EXIT

colon EMIT, "EMIT" @ ( c -- ) UARTDR ! ;
.4byte UARTDR, STORE, EXIT

@colon TYPE, "TYPE"  @ ( str -- ) BEGIN DUP C@ ?DUP NOT IF EXIT THEN EMIT 1 + AGAIN ;
@.4byte DUP, CFETCH, QDUP, BRANCHZ, +6, EMIT, DOLIT, 1, PLUS, BRANCH, -11, EXIT

native TYPE, "TYPE"
    ldr r0, =#0x4000C000
    mov r1, #0

TYPE.loop:
    ldrb r1, [rTOS]
    cmp r1, #0
    beq TYPE.done
    str r1, [r0]
    add rTOS, #1
    b TYPE.loop

TYPE.done:
    pop {rTOS}
    NEXT

colon DOT, "."  @ ( n -- )
.4byte DOLIT, 10, PAD, ROT, CALLC3, itoa, TYPE, SPACE, EXIT

colon SPACE, "SPACE"  @ ( n -- )
.4byte DOLIT, 32, EMIT, EXIT

colon WORD, "WORD" @ ( delim -- tokptr )
.4byte DROP  @ ignore delim for now
.4byte CP, FETCH, PAD, CALLC2, parse_token
.4byte CP, FETCH, PLUS, CP, STORE, PAD, EXIT

colon FIND, "FIND" @ ( tok -- xt 1 | tok 0 )
.4byte DUP, LAST, FETCH, CALLC2, find_entry  @ ( tok 0|ent )
.4byte DUP, BRANCHZ, +4, SWAP, DROP, DOLIT, 1, EXIT

colon TONUM, ">NUM" @ ( str -- n )
.4byte CALLC1, atoi, EXIT

colon WORDS, "WORDS"  @ ( -- )
.4byte HALT, LAST, FETCH  @ ( wordptr )
.4byte DUP, DOLIT, 4, PLUS, FETCH, TYPE, SPACE @ display wordname
.4byte FETCH  @ ( wordptr->prev )
.4byte QDUP, BRANCHNZ, -11, EXIT

colon CR, "CR" @ ( -- )
.4byte DOLIT, 13, EMIT, DOLIT, 10, EMIT, EXIT

colon DOTSTACK, ".S"  @ ( -- )
.4byte SP0, DUP, FETCH, DOT, DOLIT, -4, PLUS, DUP, SPFETCH, EQUAL, BRANCHZ, -11, DROP, CR, EXIT

colon DOTRSTACK, "R.S"  @ ( -- )
.4byte RP0, DUP, FETCH, DOT, DOLIT, +4, PLUS, DUP, RPFETCH, EQUAL, BRANCHZ, -11, DROP, CR, EXIT

colon TEST, "TEST" @ ( -- )
.4byte DOLIT, 10, DOLIT, 20, DOLIT, 30, DOTSTACK
.4byte TO_R, TO_R, TO_R, DOTRSTACK, RDROP, RDROP, RDROP
.4byte EXIT

@@ setup global variables
@ must go after last dictionary word for LASTWORD to be actual last word
.globl forth_init
forth_init:
    ldr r0, =kernel
    ldr r1, =CPADDR
    str r0, [r1]

    ldr r0, =LASTWORD
    ldr r1, =LASTADDR
    str r0, [r1]

    bx lr

.pool

@@@ initial source input

kernel:
    .asciz "42 23 + ."
