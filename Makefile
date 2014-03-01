NAME=pacemu
ROMS=pacman.6e pacman.6f pacman.6h pacman.6j
UNAME := $(shell uname -s)

.PHONY: dist clean

#tiles.bin: tiles.png
#	./png2bin.pl $< 6

#sprites.bin: sprites.png
#	./png2bin.pl $< 12

$(NAME).dsk: $(NAME).asm sound.bin sprites.bin tiles.bin $(ROMS)
	pyz80.py -s length -I samdos2 --exportfile=$(NAME).sym $(NAME).asm

run: $(NAME).dsk
ifeq ($(UNAME),Darwin)
	open $(NAME).dsk
else
	xdg-open $(NAME).dsk
endif

dist: $(NAME).dsk
	rm -rf dist
	mkdir dist
	cp ReadMe.txt dist/
	cp Makefile-dist dist/Makefile
	cp make.bat-dist dist/make.bat
	./remove_rom.pl
	mv disk.base dist/

clean:
	rm -f $(NAME).dsk $(NAME).sym
#	rm -f tiles.bin sprites.bin
	rm -f disk.base
	rm -rf dist
