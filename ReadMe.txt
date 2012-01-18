Pac-Man Emulator for SAM Coupe (v1.2)
-------------------------------------

The Pac-Man ROMs cannot be supplied with this program, so you must provide
your own copies of the following files (from the Midway ROM set):

  pacman.6e pacman.6f pacman.6h pacman.6j

Copy them to the same directory as this file, then run make.bat (Windows).
Under Mac/Linux/Un*x, use make to build the final pacemu.dsk disk image,
or combine manually using:

  cat disk.base pacman.6[efhj] > pacemu.dsk

Enjoy!

---

Version 1.2 (2012/01/17)
- Improved sprite draw/restore/clip code for extra speed
- Faster tile updates when no sprites are visible
- Added boot-time selection of Hard difficulty
- Added SAM joystick 1 and QAOP input methods
- Improved control handling, favouring latest direction change
- Skip RAM-check for faster startup
- Easier method to add ROMs to form final disk image


Version 1.1a (2004/10/09)
- Added build-time control of tile strip count, for Mayhem accelerator

Version 1.1 (2004/10/01)
- Changed code from Assembly Studio 8x to pyz80 (Comet) format
- Simplified build setup, moving a few things around

Version 1.0 (2004/01/17)
- Initial release

---

Simon Owen
http://simonowen.com/sam/pacemu/
