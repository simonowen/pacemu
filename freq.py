#!/usr/bin/env python
"""Generate frequency to octave+note look-up table for 0-8KHz."""

import struct
import argparse

parser = argparse.ArgumentParser("Generate frequency to octave+note look-up table")
parser.add_argument("tablefile")
args = parser.parse_args()

frequencies = {}
for octave in range(8):
    for note in range(256):
        freq = (15625 << octave) / (511.0 - note)
        frequencies[freq] = (octave, note)

outdata = []
for freq in range(8192):
    closest = min(frequencies.keys(), key=lambda f: abs(f -freq))
    octave, note = frequencies[closest]
    outdata += struct.pack('<BB', octave, note)

with open(args.tablefile, 'wb') as outfile:
    outfile.write(bytearray(outdata))
