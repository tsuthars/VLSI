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
open OUTFILE, ">$out_file";

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

say "";
say "Input Boolean Function:";
print Dumper @cube_list;

my @posCof = &positiveCofactor(0, @cube_list);
say "";
say "Positive Cofactor:";
print Dumper @posCof;


my @comp_cube_list = &Complement(@cube_list);

# Output the complemented boolean function
print OUTFILE "$num_vars\n";
my $comp_num_cubes = @comp_cube_list;
print OUTFILE "$comp_num_cubes\n";
for my $cube_ref (@comp_cube_list) {
  my @cube = @$cube_ref;
  # Compute the number of cares (or non-dont-cares)
  my $num_cares;
  for my $cube_val (@cube) {
    if ($cube_val != 3) {
      $num_cares++;
    }
  }
  # Write the cube out
  print OUTFILE "$num_cares ";
  for my $i (0..($num_vars-1)) {
    if ($cube[$i] != 3) {
      if ($cube[$i] == 1) { # Postive form of x
        print OUTFILE $i+1, " ";
      } elsif ($cube[$i] == 2) { # Negative form of x
        print OUTFILE "-", $i+1, " ";
      }
    }
  }
  print OUTFILE "\n";
}

say "";
say "Complemented Boolean Function:";
print Dumper @comp_cube_list;

sub Complement {
  my @F = @_;
  my @G; # Complemented cube list (return value)

  # Check if F is simple enough to complement directly
  if (@F == 0) { # Empty cube list
    say "Empty cube list!";
    my @cube = @dc_cube; # Empty cube list means a boolean function of "0"
    push @G, \@cube;     # whose complement is "1" represented by a dont-care cube
    return @G;
  } else {
    # Check if cube list contains the all dont-care cube
    my $dont_care_cube = 0;
    for my $cube_ref (@F) { # Go through all cubes in the cube list
      my @cube = @$cube_ref;
      $dont_care_cube = 1;       # Assume its an all dont cares cube
      for my $cube_val (@cube) { # Go through the values in the cube
        if ($cube_val != 3) {    # Found a non-dont-care value in this cube so skip to the next cube
          $dont_care_cube = 0;
          last;
        }
      }
      if ($dont_care_cube) { # Found a dont care cube so stop checking furhter in the cube list
        last;
      }
    }
    if ($dont_care_cube) { # If the cube list has a dont care cube then the boolean function is of the form stuff + "1",
      say "Cube list has the all dont-cares cube in it!";
      return @G;           # so return an empty cube list which represents a "0" which is the complement of "1"
    } elsif (@F == 1) {    # No dont-care cube and only one cube, use DeMorgan Laws to complement directly
      say "Cube list contains just one cube";
      my $cube_ref = $F[0];
      my @cube = @$cube_ref;
      for my $i (0..($num_vars-1)) {              # For each
        if ($cube[$i] == 1 or $cube[$i] == 2) {   # non dont-care term in the cube "01" or "10"
          my @comp_term = @dc_cube;               # Add a cube to the complement cube list
          $comp_term[$i] = 3^$cube[$i];           # and complement that variable
          push @G, \@comp_term;
        }
      }
      return @G;
    } else {
      say "Shouldn't come here yet";
      # Check if there are any binate variables and keep track of how many times they occur
      # in True and Complement form in the cubelist
      my @T; # Keeps track of the number of times the variable appears in True form
      my @C; # Keeps track of the number of times the variable appears in Complement form
      for my $i (0..($num_vars-1)) { # They need to be initialized to 0
        $T[$i] = 0;
        $C[$i] = 0;
      }
      for my $cube_ref (@F) {
        my @cube = @$cube_ref;
        for my $i (0..($num_vars-1)) {
          if ($cube[$i] == 1) { # Variable appears in True form
            $T[$i]++;
          } elsif ($cube[$i] == 2) { # Variable appears in Complement form
            $C[$i]++;
          }
        }
      }

      my $splitting_var; # Variable for splitting

      # Compute the binate sum
      my @binate_sum;       # Sum of T + C sorted from most to least
      my @binate_sum_var;   # Variable index for the binate_sum array
      for my $i (0..($num_vars-1)) {
        my $sum;
        $sum = $T[$i] + $C[$i];
        if ($T[$i] > 0 && $C[$i] > 0) {
          # Create the binate_sum array
          if (@binate_sum == 0 || $sum > $binate_sum[0]) {
	    # Throw away the existing array and start again
            @binate_sum = ($sum);
	    @binate_sum_var = ($i);
          } elsif ($sum == $binate_sum[0]) {
	    # Add to list at the end
	    push @binate_sum,     $sum;
	    push @binate_sum_var, $i;
          }
        }
      }
      if (@binate_sum > 1) {
        my @binate_diff;      # Difference of |T - C| sorted from least to most
        my @binate_diff_var;  # Variable index for the binate_diff array
        for my $i (@binate_sum_var) {
          my $diff;
          if ($T[$i] > $C[$i]) {
            $diff = $T[$i] - $C[$i];
          } else {
            $diff = $C[$i] - $T[$i];
          }
	  if (@binate_diff == 0 || $diff < $binate_diff[0]) {
	    # Throw away the existing array and start again
            @binate_diff     = ($diff);
	    @binate_diff_var = ($i);
          } elsif ($diff == $binate_diff[0]) {
	    # Add to list at the end
	    push @binate_diff,     $diff;
	    push @binate_diff_var, $i;
	  }
	}
	# Just choose the first one in the list since it has the smallest index as well
	$splitting_var = $binate_diff_var[0];
      } elsif (@binate_sum == 1) { # Only one most binate variable
        $splitting_var =$binate_sum_var[0];
      } else { # No binate variables
        # Compute the unate sum
        my @unate_sum;       # Sum of T + C sorted from most to least
        my @unate_sum_var;   # Variable index for the binate_sum array
        for my $i (0..($num_vars-1)) {
          my $sum;
          $sum = $T[$i] + $C[$i];
          # Create the unate_sum array
          if (@unate_sum == 0 || $sum > $unate_sum[0]) {
	    # Throw away the existing array and start again
            @unate_sum     = ($sum);
	    @unate_sum_var = ($i);
          } elsif ($sum == $unate_sum[0]) {
	    # Add to list at the end
	    push @unate_sum,     $sum;
	    push @unate_sum_var, $i;
          }
        }
	# Just choose the first one in the list since it has the smallest index as well
        $splitting_var = $unate_sum_var[0];
      }
      my @P = Complement(positiveCofactor($splitting_var, @F));
      my @N = Complement(negativeCofactor($splitting_var, @F));
      my @P = ANDxp($splitting_var, @P); 
      my @N = ANDxn($splitting_var, @N); 
      return(@P, @N);
    }
  }
}

sub positiveCofactor {
  my @F = @_;
  my $x = shift @F;
  my @G; # Positive Cofactor cube

  for my $cube_ref (@F) {
    my @cube = @$cube_ref;
    if ($cube[$x] == 1) { # If positive make it don't care
      $cube[$x] = 3;
      push @G, \@cube;
    } elsif ($cube[$x] == 3) { # Doesn't have x in it so leave cube alone
      push @G, \@cube;
    } # Otherwise remove the cube from the cube list
  }
  return @G;
}

sub negativeCofactor {
  my @F = @_;
  my $x = shift @F;
  my @G; # Negative Cofactor cube

  for my $cube_ref (@F) {
    my @cube = @$cube_ref;
    if ($cube[$x] == 2) { # If negative make it don't care
      $cube[$x] = 3;
      push @G, \@cube;
    } elsif ($cube[$x] == 3) { # Doesn't have x in it so leave cube alone
      push @G, \@cube;
    } # Otherwise remove the cube from the cube list
  }
  return @G;
}

sub ANDxp {
  my @F = @_;
  my $x = shift @F;
  my @G; # x AND F

  for my $cube_ref (@F) {
    my @cube = @$cube_ref;
    $cube[$x] = 1; # Just add the variable back in positive form
    push @G, \@cube;
  }
  return @G;
}

sub ANDxn {
  my @F = @_;
  my $x = shift @F;
  my @G; # x AND F

  for my $cube_ref (@F) {
    my @cube = @$cube_ref;
    $cube[$x] = 2; # Just add the variable back in negative form
    push @G, \@cube;
  }
  return @G;
}
