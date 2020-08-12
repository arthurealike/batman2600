all:
	dasm *.asm -f3 -v0 -ogame.bin
run:
	stella game.bin
