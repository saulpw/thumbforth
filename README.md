# a small Forth for ARM Cortex M4 (ARMv7E-M)

- install `qemu-system-arm`
- `make` to build forth.bin and run within qemu
- `make debug` then `gdb` to attach to remote server (see .gdbinit)

## Features

- outputs prompt to the serial console (Ctrl+Alt+3 in qemu)
- echoes up to 15 keystrokes

- words implemented:
  - DUP DROP SWAP QDUP
  - STORE FETCH CFETCH PLUS NOT
  - EMIT TYPE KEY HALT
  - DOLIT DOCONST DODOES
  - ENTER EXIT BRANCHZ BRANCH EXECUTE CALLC1 CALLC2
  - WORD FIND LAST WORDS

## Internals

- indirect threaded interpreter
- call C functions
- word layout in dictionary (must be const in flash):
   - [0] (prev) pointer to previous word
   - [4] (name) char * (C NUL-termined string)
   - [8] (xt) code field, pointer to native code (with thumb bit set)
   - [12] (doesip) [if codefield is DODOES] pointer to DOES IP
   - [12 or 16] (parameter field)
