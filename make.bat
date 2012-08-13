@echo off

if "%1"=="clean" goto clean
if "%1"=="dist" goto dist

rem png2bin.pl tiles.png 6
rem png2bin.pl sprites.png 12

pyz80.py --exportfile=pacemu.sym pacemu.asm
if errorlevel 1 goto end
if "%1"=="run" start pacemu.dsk
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
if exist pacemu.dsk del pacemu.dsk pacemu.sym
rem if exist tiles.bin del tiles.bin sprites.bin
if exist dist\ del dist\Makefile dist\make.bat dist\disk.base
if exist dist\pacemu.dsk del dist\pacemu.dsk
if exist dist\ rmdir dist

:end
