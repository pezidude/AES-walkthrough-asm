main:
	nasm -f elf64 printGrid.asm -o printGrid.o
	ld printGrid.o -o printGrid
	./printGrid
