#!/usr/bin/perl -w
#
# Generates a look-up table to map frequency to SAA 1099 octave/note numbers
#
# Used by the SAM Pac-Man emulator, available from:
#
#     http://simonowen.com/sam/pacemu/

$|=1;

# Loop over 8 octaves
for ($o = 0 ; $o < 8 ; $o++)
{
	# Loop over 256 note numbers
	for ($n = 0 ; $n < 256 ; $n++)
	{
		# Determine and store the frequency for the octave/note combination
		my $f = (15625 << $o) / (511-$n);
		$f{$f} = [$o,$n];
	}
}

# Build a list of frequency values (unsorted)
@f = keys %f;

open FILE, ">sound.dat" and binmode FILE or die "$!\n";

# Loop over frequencies from 0Hz to 8KHz
for ($f = 0 ; $f < 8192 ; $f++)
{
	# Find the closest frequency in the list built earlier (slow)
	my $f2 = (sort { abs($f-$a) <=> abs($f-$b) } @f)[0];

	# Write the corresponding octave and note values to the output file
	print FILE pack "CC", @{$f{$f2}};
	printf("\rBuilding table... %d%%", $f*100/8192) unless $f & 0x7f;
}

print "\rDone.                 \n";
close FILE;
