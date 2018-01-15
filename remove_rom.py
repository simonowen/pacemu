#!/usr/bin/env python

import argparse

parser = argparse.ArgumentParser("Remove ROM placeholder from pacemu master disk image")
parser.add_argument("diskimage")
parser.add_argument("baseimage")
args = parser.parse_args()

with open(args.diskimage, 'rb') as infile:
    diskdata = infile.read()

with open(args.baseimage, 'wb') as outfile:
    outfile.write(diskdata[0:819200-16384])
