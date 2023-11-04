PROGRAM = testes
ASM = mymalloc

all: testes.c $(ASM).s
	as -o $(ASM).o $(ASM).s -g
	gcc -c -o testes.o testes.c -g
	ld -o $(PROGRAM) testes.o $(ASM).o \
		-dynamic-linker /lib/x86_64-linux-gnu/ld-linux-x86-64.so.2 \
		/usr/lib/x86_64-linux-gnu/crt1.o \
		/usr/lib/x86_64-linux-gnu/crti.o \
		/usr/lib/x86_64-linux-gnu/crtn.o \
		-lc

clean:
	rm -f *.o $(PROGRAM)
