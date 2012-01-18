DISK=pacemu.dsk
ROMS=pacman.6e pacman.6f pacman.6h pacman.6j

.PHONY: dist clean

#tiles.bin: tiles.png
#	./png2bin.pl $< 6

#sprites.bin: sprites.png
#	./png2bin.pl $< 12

$(DISK): pacemu.asm sound.bin sprites.bin tiles.bin $(ROMS)
	pyz80.py --exportfile=pacemu.sym pacemu.asm

dist:
	rm -rf dist
	mkdir dist
	cp ReadMe.txt dist/
	cp Makefile-dist dist/Makefile
	cp make.bat-dist dist/make.bat
	./remove_rom.pl
	mv disk.base dist/

clean:
	rm -f $(DISK) pacemu.sym
#	rm -f tiles.bin sprites.bin
	rm -f disk.base
	rm -rf dist
