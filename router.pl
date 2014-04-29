#!/usr/local/bin/perl5.14 -w

# ASIC Router
# --------------------------------
# Reads a GRID and netlist files as inputs and routes all the nets
# using the maze routing algorithm.

use 5.014;
use warnings;
use Data::Dumper;
use autodie;

unshift @INC, "/projects/mpgIP_ext13/users/suthars/mongo_sandbox/perl_mongo/libs/lib/perl5";
unshift @INC, ".";

use Getopt::Long;
use Log::Handler;
use GridCell;
use WaveCell;
use Net;

use Heap::Priority;

my $grid_file;
my $nl_file;
my $out_file;
my $debug_level  = "info";
my $log_file     = "router.log";
my $help         = 0;
my $man          = 0;

GetOptions
  (
    "grid_file=s"   => \$grid_file,          # GRID file
    "nl_file=s"     => \$nl_file,            # Netlist file
    "out_file=s"    => \$out_file,           # Output file
    "debug_level:s" => \$debug_level,        # Debug level for printing messages
    "log_file:s"    => \$log_file,           # Log file
    'help|?'        => \$help,               # Help message
    man             => \$man                 # Manual
  );

# Create a log handler
my $log = Log::Handler->new();

# Configure the message logger
$log->add(
  file => {
    filename => $log_file,
    maxlevel => $debug_level,
    minlevel => "warning",
    newline  => 0
  },
  screen => {
    log_to   => "STDOUT",
    maxlevel => $debug_level,
    minlevel => "warning",
    newline  => 0
  }
);

# Parse the GRID file
open GRID_FILE, "$grid_file";
my $grid_file_line;
chomp($grid_file_line = <GRID_FILE>);
my ($X_gridsize, $Y_gridsize, $BendPenalty, $ViaPenalty) = split(' ', $grid_file_line);
$log->info("X_gridsize = $X_gridsize", "\n");
$log->info("Y_gridsize = $Y_gridsize", "\n");
$log->info("BendPenalty = $BendPenalty", "\n");
$log->info("ViaPenalty = $ViaPenalty", "\n");

my @grid; # Grid with both layers 1 & 2
for my $l (1..2) { # Read in layers 1 & 2
  my @init_one_layer_grid; # Initial un-routed Grid with single layer
  for my $i (0..($Y_gridsize-1)) {
    chomp($grid_file_line = <GRID_FILE>);
    my @grid_row = split(' ', $grid_file_line);
    my @grid_cell_row;
    for my $j (0..($X_gridsize-1)) {
      my $grid_cell = GridCell->new();
      $grid_cell->Cost($grid_row[$j]);
      $grid_cell->Pred('');   # Init with empty string in un-routed grid
      $grid_cell->Reached(0); # Init as un-reached
      $grid_cell_row[$j] = $grid_cell;
    }
    $init_one_layer_grid[$i] = \@grid_cell_row;
  }
  $grid[$l] = \@init_one_layer_grid;
}
close GRID_FILE;

# Parse the Netlist file
open NL_FILE, "$nl_file";
my $nl_file_line;
chomp($nl_file_line = <NL_FILE>);
my ($NetNumber) = split(' ', $nl_file_line);
$log->info("NetNumber = $NetNumber", "\n");

my @nets;
for my $i (0..($NetNumber-1)) {
  chomp($nl_file_line = <NL_FILE>);
  my ($NetID, $LayerPin1, $Xpin1, $Ypin1, $LayerPin2, $Xpin2, $Ypin2) = split(' ', $nl_file_line);
  my $net = Net->new();
  $net->NetID($NetID);
  $net->LayerPin1($LayerPin1);
  $net->Xpin1($Xpin1);
  $net->Ypin1($Ypin1);
  $net->LayerPin2($LayerPin2);
  $net->Xpin2($Xpin2);
  $net->Ypin2($Ypin2);
  $nets[$i] = $net;
}
close NL_FILE;

open OUT_FILE, ">$out_file";
print OUT_FILE $NetNumber, "\n";
for my $n (0..($NetNumber-1)) {
  # Un-block the source and target pins
  $grid[$nets[$n]->LayerPin1]->[$nets[$n]->Ypin1]->[$nets[$n]->Xpin1]->Cost(1);
  $grid[$nets[$n]->LayerPin2]->[$nets[$n]->Ypin2]->[$nets[$n]->Xpin2]->Cost(1);
  print OUT_FILE $nets[$n]->NetID, "\n";
  my $wavefront = new Heap::Priority;
  my $source_cell = WaveCell->new();
  $source_cell->x($nets[$n]->Xpin1);
  $source_cell->y($nets[$n]->Ypin1);
  $source_cell->Layer($nets[$n]->LayerPin1);
  $source_cell->Pathcost($grid[$nets[$n]->LayerPin1]->[$nets[$n]->Ypin1]->[$nets[$n]->Xpin1]->Cost);
  $source_cell->Pred(''); # Empty for source cell
  $wavefront->lowest_first; # So that next_item will return the lowest cost item
  $wavefront->add($source_cell, $source_cell->Pathcost);
  $grid[$nets[$n]->LayerPin1]->[$nets[$n]->Ypin1]->[$nets[$n]->Xpin1]->Reached(1);
  LOOP1: while (1) { # Not reached target cell
    if ($wavefront->count == 0) { # wavefront == empty
      print OUT_FILE 0, "\n";
      last LOOP1;                       # quit - no path to be found
    }
  
    my $C = $wavefront->next_item; # Get lowest cost cell on wavefront structure
    my $pred = $C->Pred;
    my @route;
    if ($C->Layer == $nets[$n]->LayerPin2 && $C->x == $nets[$n]->Xpin2 && $C->y == $nets[$n]->Ypin2) { # C == target
      #say "-----";
      #say "Route";
      #say "-----";
      # do backtrace path in grid by following pred() pointers to source
      LOOP2: while ($pred) {
        $grid[$C->Layer]->[$C->y]->[$C->x]->Cost(-1); # Mark it as un-useable for next net
        #say $C->Layer, " ", $C->x, " ", $C->y;
        #print Dumper $grid[$C->Layer]->[$C->y]->[$C->x];
        my $s = $C->Layer . " " . $C->x . " " . $C->y .  "\n";
        unshift @route, $s;
        if ($pred eq 'D' || $pred eq 'U') { # Print out the via
          my $t = "3 " . $C->x . " " . $C->y .  "\n";
          unshift @route, $t;
        }
        if ($pred eq 'N') {
          $C->y(($C->y)+1);
        } elsif ($pred eq 'S') {
          $C->y(($C->y)-1);
        } elsif ($pred eq 'E') {
          $C->x(($C->x)+1);
        } elsif ($pred eq 'W') {
          $C->x(($C->x)-1);
        } elsif ($pred eq 'D') {
          $C->Layer(($C->Layer)-1);
        } elsif ($pred eq 'U') {
          $C->Layer(($C->Layer)+1);
        }
        $pred = $grid[$C->Layer]->[$C->y]->[$C->x]->Pred;
      }
      # Add the source cell as well into the route
      $grid[$C->Layer]->[$C->y]->[$C->x]->Cost(-1); # Mark it as un-useable for next net
      #say $C->Layer, " ", $C->x, " ", $C->y;
      #print Dumper $grid[$C->Layer]->[$C->y]->[$C->x];
      my $s = $C->Layer . " " . $C->x . " " . $C->y . "\n";
      unshift @route, $s;
      print OUT_FILE @route;
      print OUT_FILE 0, "\n";
  
      # do cleanup
      for my $l (1..2) { # Layers 1 & 2
        for my $i (0..($Y_gridsize-1)) {
          for my $j (0..($X_gridsize-1)) {
            if ($grid[$l]->[$i]->[$j]->Cost > 0) { # Only cleanup cells that are not in the route
              $grid[$l]->[$i]->[$j]->Pred(''); # Remove Predecessor information for routing of next net
              $grid[$l]->[$i]->[$j]->Reached(0); # Mark it as un-reached for routing of next net
            }
          }
        }
      }
  
      # return - we found a path
      last LOOP1;
    }
  
    # foreach ( unreached neighbor N of cell C ) {
    LOOP3: while (1) {
      my $bend_cost = 0;
      my $via_cost = 0;
      my $N = WaveCell->new();
      if ($C->Layer == 1 && $C->y > 0 && $grid[$C->Layer]->[($C->y)-1]->[$C->x]->Reached == 0 && $grid[$C->Layer]->[($C->y)-1]->[$C->x]->Cost > 0) {
        $N->Layer($C->Layer);
        $N->y(($C->y)-1);
        $N->x($C->x);
        $N->Pred('N'); # mark N cell in grid with pred(N) direction back to cell C from N
        $grid[$N->Layer]->[$N->y]->[$N->x]->Pred('N'); # Also mark the predecessor in the grid
        if ($C->Pred eq 'W' || $C->Pred eq 'E') {
          $bend_cost = $BendPenalty;
        }
      } elsif ($C->Layer == 1 && $C->y < ($Y_gridsize-1) && $grid[$C->Layer]->[($C->y)+1]->[$C->x]->Reached == 0 && $grid[$C->Layer]->[($C->y)+1]->[$C->x]->Cost > 0) {
        $N->Layer($C->Layer);
        $N->y(($C->y)+1);
        $N->x($C->x);
        $N->Pred('S'); # mark N cell in grid with pred(N) direction back to cell C from N
        $grid[$N->Layer]->[$N->y]->[$N->x]->Pred('S'); # Also mark the predecessor in the grid
        if ($C->Pred eq 'W' || $C->Pred eq 'E') {
          $bend_cost = $BendPenalty;
        }
      } elsif ($C->Layer == 2 && $C->x > 0 && $grid[$C->Layer]->[$C->y]->[($C->x)-1]->Reached == 0 && $grid[$C->Layer]->[$C->y]->[($C->x)-1]->Cost > 0) {
        $N->Layer($C->Layer);
        $N->y($C->y);
        $N->x(($C->x)-1);
        $N->Pred('E'); # mark N cell in grid with pred(N) direction back to cell C from N
        $grid[$N->Layer]->[$N->y]->[$N->x]->Pred('E'); # Also mark the predecessor in the grid
        if ($C->Pred eq 'N' || $C->Pred eq 'S') {
          $bend_cost = $BendPenalty;
        }
      } elsif ($C->Layer == 2 && $C->x < ($X_gridsize-1) && $grid[$C->Layer]->[$C->y]->[($C->x)+1]->Reached == 0 && $grid[$C->Layer]->[$C->y]->[($C->x)+1]->Cost > 0) {
        $N->Layer($C->Layer);
        $N->y($C->y);
        $N->x(($C->x)+1);
        $N->Pred('W'); # mark N cell in grid with pred(N) direction back to cell C from N
        $grid[$N->Layer]->[$N->y]->[$N->x]->Pred('W'); # Also mark the predecessor in the grid
        if ($C->Pred eq 'N' || $C->Pred eq 'S') {
          $bend_cost = $BendPenalty;
        }
      } elsif ($C->Layer == 1 && $grid[($C->Layer)+1]->[$C->y]->[$C->x]->Reached == 0 && $grid[($C->Layer)+1]->[$C->y]->[$C->x]->Cost > 0) { # Going up a layer
        $N->Layer(($C->Layer)+1);
        $N->y($C->y);
        $N->x($C->x);
        $N->Pred('D'); # mark N cell in grid with pred(N) direction back to cell C from N (Down)
        $grid[$N->Layer]->[$N->y]->[$N->x]->Pred('D'); # Also mark the predecessor in the grid
        $via_cost = $ViaPenalty;
      } elsif ($C->Layer == 2 && $grid[($C->Layer)-1]->[$C->y]->[$C->x]->Reached == 0 && $grid[($C->Layer)-1]->[$C->y]->[$C->x]->Cost > 0) { # Going down a layer
        $N->Layer(($C->Layer)-1);
        $N->y($C->y);
        $N->x($C->x);
        $N->Pred('U'); # mark N cell in grid with pred(N) direction back to cell C from N (Up)
        $grid[$N->Layer]->[$N->y]->[$N->x]->Pred('U'); # Also mark the predecessor in the grid
        $via_cost = $ViaPenalty;
      } else {
        last LOOP3; # Reached all neighbors
      }
      $grid[$N->Layer]->[$N->y]->[$N->x]->Reached(1); # mark N cell in grid as reached
      #say $N->Layer, " ", $N->x, " ", $N->y;
      #print Dumper $grid[$N->Layer]->[$N->y]->[$N->x];
      # compute cost to reach
      $N->Pathcost($C->Pathcost + $grid[$N->Layer]->[$N->y]->[$N->x]->Cost + $bend_cost + $via_cost); # pathcost(N) = pathcost(C) + cellcost(N) + BendPenalty(if any) + ViaPenalty(if any)
      $wavefront->add($N, $N->Pathcost); # add this cell N to wavefront, indexed by pathcost(N)
    }
    $wavefront->pop; # delete cell C from wavefront
  }
}
close OUT_FILE;
