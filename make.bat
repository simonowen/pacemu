@echo off
setlocal
set NAME=pacemu

if "%1"=="clean" goto clean

set CLUT=0,127,34,123,85,106,110,96,6,68,29,25,99,122,126,119
tile2sam.py -q --tiles 102 --clut %CLUT% --pal sprites.png 12x12
tile2sam.py -q --tiles 252 --clut sprites.pal tiles.png 6x6

if not exist sound.bin freq.py sound.bin

pyz80.py -s length -I samdos2 --mapfile=%NAME%.map %NAME%.asm
if errorlevel 1 goto end

if "%1"=="dist" goto dist
if "%1"=="run" start %NAME%.dsk
if "%1"=="net" SAMdisk %NAME%.dsk sam:
goto end

:dist
if not exist dist mkdir dist
copy ReadMe.txt dist\
copy Makefile-dist dist\Makefile
copy make.bat-dist dist\make.bat
remove_rom.py pacemu-master.dsk dist\disk.base
goto end

:clean
if exist %NAME%.dsk del %NAME%.dsk %NAME%.map
if exist tiles.bin del sprites.bin tiles.bin
if exist sound.bin del sound.bin
if exist dist\ del dist\ReadMe.txt dist\Makefile dist\make.bat dist\disk.base
if exist dist\%NAME%.dsk del dist\%NAME%.dsk
if exist dist\ rmdir dist

:end
endlocal
