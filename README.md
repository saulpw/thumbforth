# a small Forth for ARM Cortex M4 (ARMv7E-M)

- install `qemu-system-arm`
- `make` to build forth.bin and run within qemu
- `make debug` then `gdb` to attach to remote server (see .gdbinit)

## Features

- outputs prompt to the serial console (Ctrl+Alt+3 in qemu)
- echoes up to 15 keystrokes

- words implemented:
  - DUP DROP SWAP QDUP
  - STORE FETCH CFETCH PLUS
  - EMIT TYPE KEY HALT
  - DOLIT DOCONST DOVAR
  - ENTER EXIT BRANCHZ BRANCH
  - WORD

## Internals

- indirect threaded interpreter
- call C functions
