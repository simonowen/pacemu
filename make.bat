@echo off
setlocal
set NAME=pacemu

if "%1"=="clean" goto clean

rem png2bin.pl tiles.png 6
rem png2bin.pl sprites.png 12

pyz80.py -s length -I samdos2 --exportfile=%NAME%.sym %NAME%.asm
if errorlevel 1 goto end

if "%1"=="dist" goto dist

if "%1"=="run" start %NAME%.dsk
goto end

:dist
if not exist dist mkdir dist
copy ReadMe.txt dist\
copy Makefile-dist dist\Makefile
copy make.bat-dist dist\make.bat
remove_rom.pl
move disk.base dist\
goto end

:clean
if exist %NAME%.dsk del %NAME%.dsk %NAME%.sym
rem if exist tiles.bin del tiles.bin sprites.bin
if exist dist\ del dist\ReadMe.txt dist\Makefile dist\make.bat dist\disk.base
if exist dist\%NAME%.dsk del dist\%NAME%.dsk
if exist dist\ rmdir dist

:end
endlocal
