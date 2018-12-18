AFLAGS=-Wa,-mimplicit-it=always
CFLAGS=-mthumb -ggdb
LDPATH=/usr/lib/gcc/arm-none-eabi/6.3.1/thumb/v7e-m/

all: run

%.o: %.c
	arm-none-eabi-gcc $(CFLAGS) $< -c -o $@

forth.o: forth.S
	arm-none-eabi-gcc $(AFLAGS) $< -c -o $@

forth.elf: forth.o parse.o
	arm-none-eabi-ld $^ -L$(LDPATH) -lgcc -o $@ -T lm3s6965.ld

forth.bin: forth.elf
	arm-none-eabi-objdump -D $< > $@.lst
	arm-none-eabi-objcopy $< -O binary $@

run: forth.bin
	qemu-system-arm -machine lm3s6965evb -s -kernel $<

debug: forth.bin
	qemu-system-arm -machine lm3s6965evb -S -s -d guest_errors -kernel $<

clean:
	rm *.o *.elf *.bin *.lst
