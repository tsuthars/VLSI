#!/usr/bin/perl

use 5.014;
use warnings;
use Data::Dumper;
use autodie;

my $in_file  = $ARGV[0];
my $out_file = $ARGV[1];

open INFILE, "$in_file";

chomp(my $num_vars = <INFILE>);
chomp(my $num_cubes = <INFILE>);

my@cube_list;
my @dc_cube;
for my $i (0..($num_vars-1)) {
  push @dc_cube, 3;
}

my @cube_list;
for my $i (0..($num_cubes-1)) {
  my $cube_line = <INFILE>;
  my @cube_vals = split /\s+/, $cube_line;
  my $num_cares = shift @cube_vals;
  my @cube = @dc_cube;
  for my $j (@cube_vals) {
    if ($j>0) {
      $cube[$j-1] = 1;
    } else {
      $cube[-$j-1] = 2;
    }
  }
  push @cube_list, \@cube;
}

print Dumper @cube_list;
