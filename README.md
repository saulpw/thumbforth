# a small Forth for ARM Cortex M4 (ARMv7E-M)

- install `qemu-system-arm`
- `make` to build .bin and .lst
- `gdb` to attach to remote server (see .gdbinit)

## Features

- outputs `HI` to the serial console (Ctrl+Alt+3 in qemu)
- indirect threaded interpreter
- words: DUP DROP SWAP EMIT HALT DOLITERAL ENTER EXIT
