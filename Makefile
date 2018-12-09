CFLAGS=-Wa,-mimplicit-it=always -c

all: run

forth.o: forth.S
	arm-none-eabi-gcc $(CFLAGS) $< -o $@

forth.elf: forth.o
	arm-none-eabi-ld $< -o $@ -T lm3s6965.ld

forth.bin: forth.elf
	arm-none-eabi-objdump -D $< > $@.lst
	arm-none-eabi-objcopy $< -O binary $@

run: forth.bin
	qemu-system-arm -machine lm3s6965evb -s -kernel $<

debug: forth.bin
	qemu-system-arm -machine lm3s6965evb -S -s -kernel $<
