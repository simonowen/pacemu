NAME=pacemu
ROMS=pacman.6e pacman.6f pacman.6h pacman.6j
CLUT=0,127,34,123,85,106,110,96,6,68,29,25,99,122,126,119
UNAME := $(shell uname -s)

.PHONY: dist clean

$(NAME).dsk: $(NAME).asm sound.bin sprites.bin tiles.bin $(ROMS)
	pyz80.py -s length -I samdos2 --mapfile=$(NAME).map $(NAME).asm

sprites.bin: sprites.png
	tile2sam.py -q --tiles 102 --clut $(CLUT) --pal sprites.png 12x12

tiles.bin: tiles.png sprites.bin
	tile2sam.py -q --tiles 252 --clut sprites.pal tiles.png 6x6

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
	./remove_rom.py pacemu-master.dsk dist/disk.base

clean:
	rm -f $(NAME).dsk $(NAME).map
	rm -f tiles.bin sprites.bin
	rm -rf dist
