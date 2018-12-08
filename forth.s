.equ UARTDR, 0x4000C000

.text
.thumb

.word 0x20000ffc @ initial SP
.word _reset     @ reset PC
.word _exc2      @ nmi
.word _exc3      @ hard fault
.word _exc4      @ mm fault
.word _exc5      @ bus fault
.word _exc6      @ usage fault

.globl _reset
.thumb_func
_reset:
    ldr r0, =UARTDR
    mov r1, #'F'
    str r1, [r0]
loop: b loop

.arm
_exc2: b _exc2
_exc3: b _exc3
_exc4: b _exc4
_exc5: b _exc5
_exc6: b _exc6
