# a small Forth for ARM Cortex M4 (ARMv7E-M)

- install `qemu-system-arm`
- `make` to build forth.bin and run within qemu
- `make debug` then `gdb` to attach to remote server (see .gdbinit)

## Features

- outputs `OK` to the serial console (Ctrl+Alt+3 in qemu)
- echoes up to 15 keystrokes

- words implemented:
  - DUP DROP SWAP QDUP
  - EMIT KEY HALT
  - DOLIT ENTER EXIT BRANCHZ BRANCH

## Internals

- indirect threaded interpreter
