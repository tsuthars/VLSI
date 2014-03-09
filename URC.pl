#!/usr/bin/perl

# Unate Recursive Complement (URC)
# --------------------------------
# Reads a boolean function from a file and computes
# the inverse boolean function using URC.
# It uses Positonal Cubic Notation (PCN) data structure to store
# the boolean function

use 5.014;
use warnings;
use Data::Dumper;
use autodie;

my $in_file  = $ARGV[0];
my $out_file = $ARGV[1];

open INFILE, "$in_file";

chomp(my $num_vars = <INFILE>);  # Number of variables in the boolean function x1, x2, x3, etc.
chomp(my $num_cubes = <INFILE>); # Number of cubes in the function which is also the number of lines rmeianing in the input file

my @cube_list; # Input cube list
my @dc_cube;  # Create a dont-care cube list with appropriate number of variables for re-use
for my $i (0..($num_vars-1)) {
  push @dc_cube, 3;  # 3 or "11" represents dont-care value
}

for my $i (0..($num_cubes-1)) {
  my $cube_line = <INFILE>;
  my @cube_vals = split /\s+/, $cube_line;
  my $num_cares = shift @cube_vals; # Get the number of non-dont-care vlaues (ie. care values)
  my @cube = @dc_cube;              # Init with the dont-care cube
  for my $j (@cube_vals) {
    if ($j>0) {                     # Greater than 0 means x
      $cube[$j-1] = 1;              # which is represented by
    } else {
      $cube[-$j-1] = 2;
    }
  }
  push @cube_list, \@cube;
}

print Dumper @cube_list;
