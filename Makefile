AFLAGS=-Wa,-mimplicit-it=always
CFLAGS=-mthumb -Os

all: run

%.o: %.c
	arm-none-eabi-gcc $(CFLAGS) $< -c -o $@

forth.o: forth.S
	arm-none-eabi-gcc $(AFLAGS) $< -c -o $@

forth.elf: forth.o parse.o
	arm-none-eabi-ld $^ -o $@ -T lm3s6965.ld

forth.bin: forth.elf
	arm-none-eabi-objdump -D $< > $@.lst
	arm-none-eabi-objcopy $< -O binary $@

run: forth.bin
	qemu-system-arm -machine lm3s6965evb -s -kernel $<

debug: forth.bin
	qemu-system-arm -machine lm3s6965evb -S -s -d guest_errors -kernel $<

clean:
	rm *.o *.elf *.bin *.lst
