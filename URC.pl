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

for my $i (0..($num_cubes-1)) { # Read in all the cubes from the input file
  my $cube_line = <INFILE>;
  my @cube_vals = split /\s+/, $cube_line;
  my $num_cares = shift @cube_vals; # Get the number of non-dont-care values (ie. care values)
  my @cube = @dc_cube;              # Init with the dont-care cube
  for my $j (@cube_vals) {
    if ($j>0) {                     # Greater than 0 means x,
      $cube[$j-1] = 1;              # which is represented by 1 or "01"
    } else {                        # Less than 0 means x' (not x),
      $cube[-$j-1] = 2;             # which is represented by 2 or "10"
    }
  }
  push @cube_list, \@cube;
}

@comp_cube_list = &Complement(@cube_list);

print Dumper @cube_list;

sub Complement {
  my @F = @_;

  my @G; # Complemented cube list (return value)
  # Check if F is simple enough to complement directly
  if (@F == 0) { # Empty cube list
    say "Empty cube list";
    my @cube = @dc_cube; # Empty cube list means a boolean function of "0"
    push @G, \@cube;     # whose complement is "1" represented by a dont-care cube
    return @G;
  } else {
    # Check if cube list contains the all dont-care cube
    my $dont_care_cube = 0;
    for my @cube (@F) {
      if (@cube == @dc_cube) {
        $dont_care_cube = 1;
        last;
      }
    }
    if ($dont_care_cube) { # If the cube list has a dont care cube then the boolean function is of the form stuff + "1",
      return @G;           # so return an empty cube list which represents a "0" which is the complement of "1"
    } elsif (@F == 1) {    # No dont-care cube and only one cube, use DeMorgan Laws to complement directly
      say "Cube list contains just one cube";
      my $cube_ref = $F[0];
      my @cube = @$cube_ref;
      for my $cube_val (@cube)
    } else {
      say "Shouldn't come here yet";
    }
}
