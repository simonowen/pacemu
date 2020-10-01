# Pac-Man Emulator for SAM Coupé v1.4

## Introduction

This program emulates the Pac-Man hardware environment, allowing the arcade
Pac-Man ROMs to run (almost) unmodified on the SAM Coupé. The Z80 code is
executed natively, but the sprite and tile display hardware is emulated. The
sound and input are mapped to the closest SAM equivalents.

## Requirements

The Pac-Man ROMs cannot be distributed with this program, so you must provide
your own copies of the following files (from the Midway ROM set):

```
  pacman.6e pacman.6f pacman.6h pacman.6j
```

## Usage

The `pacemu.dsk` disk image is created by combining the supplied disk image
fragments with the Pac-Man ROM images:

 1) Copy the Pac-Man ROM images (detailed above) to the pacemu directory.
 2) Windows users: run `make.bat`. Linux/Mac/Unix users run `make`.
 3) Open the .dsk image with a SAM emulator, such as SimCoupe.

## Controls

|                 Key | Action                                 |
|--------------------:|:---------------------------------------|
|                   1 | 1 Player Start                         |
|                   2 | 2 Player Start                         |
|                   3 | Insert Coin                            |
|                  F9 | Hard difficulty (hold during ROM boot) |
|         Cursor Keys | Joystick Control                       |
|             Q/A/O/P | Joystick Control                       |
|      SAM Joystick 1 | Joystick Control                       |

To check the difficulty setting, watch the cyan ghost at the start of the game.
On Hard it exits the ghost box immediately, on Normal it waits around 6 seconds.

## Build From Source

You may also build the emulator from source code, which requires a few extra
tools.

### Prerequisites

- The pacemu [source code](https://github.com/simonowen/pacemu).
- The arcade Pac-Man ROM images detailed above.
- [tile2sam.py](https://github.com/simonowen/tile2sam) to create sprite data.
- [pyz80.py](https://github.com/simonowen/pyz80) assembler to build Z80 code.

Ensure `tile2sam.py` and `pyz80.py` are in your path, then run `make.bat` (Windows)
or `make` (Linux/Mac/Unix) to generate `pacemu.dsk`.

---

## Changelog

### Version 1.4 (2014/03/01)
- Added support for diagonal control inputs from keyboard and 8-way joysticks

### Version 1.3 (2012/08/04)
- Added screen clear for compatibility with ROMs that skip RAM wipe

### Version 1.2 (2012/01/18)
- Improved sprite draw/restore/clip code for extra speed
- Faster tile updates when no sprites are visible
- Added boot-time selection of Hard difficulty
- Added SAM joystick 1 and QAOP input methods
- Improved control handling, favouring latest direction change
- Skip RAM-check for faster startup
- Easier method to add ROMs to form final disk image

### Version 1.1a (2004/10/09)
- Added build-time control of tile strip count, for Mayhem accelerator

### Version 1.1 (2004/10/01)
- Changed code from Assembly Studio 8x to pyz80 (Comet) format
- Simplified build setup, moving a few things around

### Version 1.0 (2004/01/17)
- Initial release

---

Simon Owen  
https://simonowen.com/sam/pacemu/
