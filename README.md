# a small Forth for ARM Cortex M4 (ARMv7E-M)

- install `qemu-system-arm`
- `make` to build forth.bin and run within qemu
- `make debug` then `gdb` to attach to remote server (see .gdbinit)

## Features

- outputs prompt to the serial console (Ctrl+Alt+3 in qemu)
- echoes up to 15 keystrokes before UART goes haywire

- words implemented:
  - `DUP DROP SWAP ROT ?DUP`
  - `! @ C@ + NOT`
  - `EMIT TYPE CR SPACE . KEY HALT`
  - `DOLIT DOCONST DODOES`
  - `ENTER EXIT BRANCHZ BRANCH EXECUTE CALLC1 CALLC2 CALLC3`
  - `WORD FIND LAST WORDS`
  - `SP0 SP@ .S`
  - `RP0 RP@ R.S R> >R RDROP`

## Internals

- indirect threaded interpreter
- word layout in dictionary (must be const in flash):
   - [0] (prev) pointer to previous word
   - [4] (name) char * (C NUL-termined string)
   - [8] (xt) code field, pointer to native code (with thumb bit set)
   - [12] (doesip) [if codefield is DODOES] pointer to DOES IP
   - [12 or 16] (parameter field)

- `CALLC3 ( a b c -- foo[a,b,c] )` calls C function `foo` (next in the instruction stream) with the given parameters passed from the Forth stack.  Same for `CALLC1` and `CALLC2` but with fewer parameters.
